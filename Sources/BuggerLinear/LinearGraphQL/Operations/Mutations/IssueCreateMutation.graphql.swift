// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI

extension LinearGraphQL {
  class IssueCreateMutation: GraphQLMutation {
    static let operationName: String = "IssueCreate"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation IssueCreate($input: IssueCreateInput!) { issueCreate(input: $input) { __typename success issue { __typename id title } } }"#
      ))

    public var input: IssueCreateInput

    public init(input: IssueCreateInput) {
      self.input = input
    }

    public var __variables: Variables? { ["input": input] }

    struct Data: LinearGraphQL.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: ApolloAPI.ParentType { LinearGraphQL.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("issueCreate", IssueCreate.self, arguments: ["input": .variable("input")]),
      ] }

      /// Creates a new issue.
      var issueCreate: IssueCreate { __data["issueCreate"] }

      /// IssueCreate
      ///
      /// Parent Type: `IssuePayload`
      struct IssueCreate: LinearGraphQL.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: ApolloAPI.ParentType { LinearGraphQL.Objects.IssuePayload }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("success", Bool.self),
          .field("issue", Issue?.self),
        ] }

        /// Whether the operation was successful.
        var success: Bool { __data["success"] }
        /// The issue that was created or updated.
        var issue: Issue? { __data["issue"] }

        /// IssueCreate.Issue
        ///
        /// Parent Type: `Issue`
        struct Issue: LinearGraphQL.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: ApolloAPI.ParentType { LinearGraphQL.Objects.Issue }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", LinearGraphQL.ID.self),
            .field("title", String.self),
          ] }

          /// The unique identifier of the entity.
          var id: LinearGraphQL.ID { __data["id"] }
          /// The issue's title.
          var title: String { __data["title"] }
        }
      }
    }
  }

}
