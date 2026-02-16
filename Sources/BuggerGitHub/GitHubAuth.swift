import AuthenticationServices
import Foundation
import Security
import UIKit

public struct GitHubOAuthAppConfig: Sendable {
    public let clientId: String
    public let clientSecret: String
    public let redirectScheme: String
    public let redirectPath: String
    public let scope: String

    public init(
        clientId: String,
        clientSecret: String,
        redirectScheme: String = "buggerdemo",
        redirectPath: String = "oauth",
        scope: String = "repo"
    ) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectScheme = redirectScheme
        self.redirectPath = redirectPath
        self.scope = scope
    }

    public var redirectURI: String {
        "\(redirectScheme)://\(redirectPath)"
    }

    public var isConfigured: Bool {
        let trimmedClientId = clientId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSecret = clientSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedClientId.isEmpty, !trimmedSecret.isEmpty else {
            return false
        }
        return !trimmedClientId.contains("TODO") && !trimmedSecret.contains("TODO")
    }
}

@MainActor
public final class GitHubOAuthClient: NSObject {
    public static let shared = GitHubOAuthClient()

    public var appConfiguration: GitHubOAuthAppConfig?

    private var session: ASWebAuthenticationSession?
    private var presentationAnchor: ASPresentationAnchor?

    public var isConfigured: Bool {
        appConfiguration?.isConfigured ?? false
    }

    public func login() async throws -> String {
        guard let config = appConfiguration, config.isConfigured else {
            throw GitHubAuthError.missingClientConfig
        }

        let state = UUID().uuidString
        let authorizeURL = try makeAuthorizeURL(state: state, config: config)
        let callbackScheme = config.redirectScheme

        let code = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            guard let anchor = Self.findPresentationAnchor() else {
                continuation.resume(throwing: GitHubAuthError.missingPresentationAnchor)
                return
            }

            self.presentationAnchor = anchor
            let session = ASWebAuthenticationSession(
                url: authorizeURL,
                callbackURLScheme: callbackScheme
            ) { callbackURL, error in
                if let error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: GitHubAuthError.cancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }

                guard let callbackURL else {
                    continuation.resume(throwing: GitHubAuthError.invalidCallback)
                    return
                }

                guard let items = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems else {
                    continuation.resume(throwing: GitHubAuthError.invalidCallback)
                    return
                }

                let code = items.first(where: { $0.name == "code" })?.value
                let returnedState = items.first(where: { $0.name == "state" })?.value

                guard returnedState == state else {
                    continuation.resume(throwing: GitHubAuthError.stateMismatch)
                    return
                }

                guard let code, !code.isEmpty else {
                    continuation.resume(throwing: GitHubAuthError.missingCode)
                    return
                }

                continuation.resume(returning: code)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            self.session = session

            if !session.start() {
                continuation.resume(throwing: GitHubAuthError.sessionStartFailed)
            }
        }

        self.session = nil
        return try await exchangeCodeForToken(code: code, state: state, config: config)
    }

    private func makeAuthorizeURL(state: String, config: GitHubOAuthAppConfig) throws -> URL {
        var components = URLComponents(string: "https://github.com/login/oauth/authorize")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "redirect_uri", value: config.redirectURI),
            URLQueryItem(name: "scope", value: config.scope),
            URLQueryItem(name: "state", value: state)
        ]
        guard let url = components?.url else {
            throw GitHubAuthError.invalidAuthorizeURL
        }
        return url
    }

    private func exchangeCodeForToken(
        code: String,
        state: String,
        config: GitHubOAuthAppConfig
    ) async throws -> String {
        let url = URL(string: "https://github.com/login/oauth/access_token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "client_secret", value: config.clientSecret),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: config.redirectURI),
            URLQueryItem(name: "state", value: state)
        ]
        request.httpBody = components.query?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubAuthError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw GitHubAuthError.requestFailed(status: httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(GitHubTokenResponse.self, from: data)
        if let error = decoded.error {
            throw GitHubAuthError.tokenExchangeFailed(error)
        }
        guard let token = decoded.accessToken, !token.isEmpty else {
            throw GitHubAuthError.missingAccessToken
        }
        return token
    }

    private static func findPresentationAnchor() -> ASPresentationAnchor? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

extension GitHubOAuthClient: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        presentationAnchor ?? ASPresentationAnchor()
    }
}

struct GitHubTokenResponse: Decodable {
    let accessToken: String?
    let scope: String?
    let tokenType: String?
    let error: String?

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case scope
        case tokenType = "token_type"
        case error
    }
}

public enum GitHubTokenStore {
    private static var service: String {
        let bundleId = Bundle.main.bundleIdentifier ?? "com.bugger"
        return "\(bundleId).github"
    }
    private static let account = "oauth-token"

    public static func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return token
    }

    public static func save(_ token: String) throws {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemAdd((query.merging(attributes) { $1 }) as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            if updateStatus != errSecSuccess {
                throw GitHubAuthError.keychainSaveFailed
            }
        } else if status != errSecSuccess {
            throw GitHubAuthError.keychainSaveFailed
        }
    }

    public static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

public enum GitHubAuthError: LocalizedError {
    case missingClientConfig
    case missingPresentationAnchor
    case invalidAuthorizeURL
    case invalidCallback
    case missingCode
    case stateMismatch
    case sessionStartFailed
    case invalidResponse
    case requestFailed(status: Int)
    case tokenExchangeFailed(String)
    case missingAccessToken
    case keychainSaveFailed
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .missingClientConfig:
            return "GitHub OAuth client ID/secret are missing."
        case .missingPresentationAnchor:
            return "Unable to present GitHub login."
        case .invalidAuthorizeURL:
            return "Failed to build the GitHub authorize URL."
        case .invalidCallback:
            return "GitHub callback URL was invalid."
        case .missingCode:
            return "No authorization code was returned."
        case .stateMismatch:
            return "GitHub login state mismatch."
        case .sessionStartFailed:
            return "Could not start the GitHub login session."
        case .invalidResponse:
            return "GitHub token response was invalid."
        case .requestFailed(let status):
            return "GitHub token request failed (HTTP \(status))."
        case .tokenExchangeFailed(let message):
            return "GitHub token exchange failed: \(message)."
        case .missingAccessToken:
            return "GitHub token response did not include an access token."
        case .keychainSaveFailed:
            return "Saving the GitHub token to Keychain failed."
        case .cancelled:
            return "GitHub login was cancelled."
        }
    }
}
