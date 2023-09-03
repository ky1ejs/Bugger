import BuggerGitHub

struct ExampleGitHubConfig {
    static func build() -> GitHubConfig {
        return GitHubConfig(
            token: "",
            owner: "",
            repo: "",
            imgurClientId: ""
        )
    }
}
