//
//  ReportViewController.swift
//  BuggerLinear
//
//  Created by Kyle Satti on 9/1/23.
//  Copyright © 2023 Kyle McAlpine. All rights reserved.
//

import UIKit
import Bugger
import Apollo
import ApolloAPI

@MainActor
public class ReportViewController: UIViewController {
    private let reportParams: ReportParams
    private let linearConfig: LinearConfig
    private var reportView: ReportView!
    private lazy var apolloClient: ApolloClient = makeApolloClient()

    public init(reportParams: ReportParams, linearConfig: LinearConfig) {
        self.reportParams = reportParams
        self.linearConfig = linearConfig
        super.init(nibName: nil, bundle: nil)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(send))
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func loadView() {
        reportView = ReportView(screenshot: reportParams.screenshot)
        view = reportView
    }

    @objc func send() {
        let input = LinearGraphQL.IssueCreateInput(
            title: .some(reportView.titleTF.text!),
            description: .some(reportView.descriptionTF.text),
            teamId: linearConfig.teamId
        )
        let mutation = LinearGraphQL.IssueCreateMutation(input: input)

        Task { @MainActor in
            apolloClient.perform(mutation: mutation) { [weak self] result in
                print(result)
                self?.reportParams.completionHandler()
            }
        }
    }

    private func makeApolloClient() -> ApolloClient {
        let client = URLSessionClient()
        let cache = InMemoryNormalizedCache()
        let store = ApolloStore(cache: cache)
        let provider = AuthorizationInterceptorProvider(apiKey: linearConfig.apiKey, client: client, store: store)
        let url = URL(string: "https://api.linear.app/graphql")!
        let transport = RequestChainNetworkTransport(interceptorProvider: provider, endpointURL: url)
        return ApolloClient(networkTransport: transport, store: store)
    }
}

enum ReportViewControllerState {
    case editing
    case loading(UIActivityIndicatorView)
}

final class AuthorizationInterceptor: ApolloInterceptor {
    public var id: String = UUID().uuidString
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func interceptAsync<Operation>(
        chain: RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) where Operation: GraphQLOperation {
        request.addHeader(name: "Authorization", value: apiKey)
        chain.proceedAsync(
            request: request,
            response: response,
            interceptor: self,
            completion: completion
        )
    }
}

final class AuthorizationInterceptorProvider: DefaultInterceptorProvider {
    private let apiKey: String

    init(apiKey: String, client: URLSessionClient, store: ApolloStore) {
        self.apiKey = apiKey
        super.init(client: client, store: store)
    }

    override func interceptors<Operation>(for operation: Operation) -> [ApolloInterceptor] where Operation: GraphQLOperation {
        var interceptors = super.interceptors(for: operation)
        interceptors.insert(AuthorizationInterceptor(apiKey: apiKey), at: 0)
        return interceptors
    }
}

