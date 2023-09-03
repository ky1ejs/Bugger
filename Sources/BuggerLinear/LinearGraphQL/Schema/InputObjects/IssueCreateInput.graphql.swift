// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

extension LinearGraphQL {
  struct IssueCreateInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      id: GraphQLNullable<String> = nil,
      title: GraphQLNullable<String> = nil,
      description: GraphQLNullable<String> = nil,
      descriptionData: GraphQLNullable<JSON> = nil,
      assigneeId: GraphQLNullable<String> = nil,
      parentId: GraphQLNullable<String> = nil,
      priority: GraphQLNullable<Int> = nil,
      estimate: GraphQLNullable<Int> = nil,
      subscriberIds: GraphQLNullable<[String]> = nil,
      labelIds: GraphQLNullable<[String]> = nil,
      teamId: String,
      cycleId: GraphQLNullable<String> = nil,
      projectId: GraphQLNullable<String> = nil,
      projectMilestoneId: GraphQLNullable<String> = nil,
      stateId: GraphQLNullable<String> = nil,
      referenceCommentId: GraphQLNullable<String> = nil,
      boardOrder: GraphQLNullable<Double> = nil,
      sortOrder: GraphQLNullable<Double> = nil,
      subIssueSortOrder: GraphQLNullable<Double> = nil,
      dueDate: GraphQLNullable<TimelessDate> = nil,
      createAsUser: GraphQLNullable<String> = nil,
      displayIconUrl: GraphQLNullable<String> = nil,
      preserveSortOrderOnCreate: GraphQLNullable<Bool> = nil,
      createdAt: GraphQLNullable<DateTime> = nil,
      slaBreachesAt: GraphQLNullable<DateTime> = nil,
      templateId: GraphQLNullable<String> = nil
    ) {
      __data = InputDict([
        "id": id,
        "title": title,
        "description": description,
        "descriptionData": descriptionData,
        "assigneeId": assigneeId,
        "parentId": parentId,
        "priority": priority,
        "estimate": estimate,
        "subscriberIds": subscriberIds,
        "labelIds": labelIds,
        "teamId": teamId,
        "cycleId": cycleId,
        "projectId": projectId,
        "projectMilestoneId": projectMilestoneId,
        "stateId": stateId,
        "referenceCommentId": referenceCommentId,
        "boardOrder": boardOrder,
        "sortOrder": sortOrder,
        "subIssueSortOrder": subIssueSortOrder,
        "dueDate": dueDate,
        "createAsUser": createAsUser,
        "displayIconUrl": displayIconUrl,
        "preserveSortOrderOnCreate": preserveSortOrderOnCreate,
        "createdAt": createdAt,
        "slaBreachesAt": slaBreachesAt,
        "templateId": templateId
      ])
    }

    /// The identifier in UUID v4 format. If none is provided, the backend will generate one.
    var id: GraphQLNullable<String> {
      get { __data["id"] }
      set { __data["id"] = newValue }
    }

    /// The title of the issue.
    var title: GraphQLNullable<String> {
      get { __data["title"] }
      set { __data["title"] = newValue }
    }

    /// The issue description in markdown format.
    var description: GraphQLNullable<String> {
      get { __data["description"] }
      set { __data["description"] = newValue }
    }

    /// The issue description as a Prosemirror document.
    var descriptionData: GraphQLNullable<JSON> {
      get { __data["descriptionData"] }
      set { __data["descriptionData"] = newValue }
    }

    /// The identifier of the user to assign the issue to.
    var assigneeId: GraphQLNullable<String> {
      get { __data["assigneeId"] }
      set { __data["assigneeId"] = newValue }
    }

    /// The identifier of the parent issue.
    var parentId: GraphQLNullable<String> {
      get { __data["parentId"] }
      set { __data["parentId"] = newValue }
    }

    /// The priority of the issue. 0 = No priority, 1 = Urgent, 2 = High, 3 = Normal, 4 = Low.
    var priority: GraphQLNullable<Int> {
      get { __data["priority"] }
      set { __data["priority"] = newValue }
    }

    /// The estimated complexity of the issue.
    var estimate: GraphQLNullable<Int> {
      get { __data["estimate"] }
      set { __data["estimate"] = newValue }
    }

    /// The identifiers of the users subscribing to this ticket.
    var subscriberIds: GraphQLNullable<[String]> {
      get { __data["subscriberIds"] }
      set { __data["subscriberIds"] = newValue }
    }

    /// The identifiers of the issue labels associated with this ticket.
    var labelIds: GraphQLNullable<[String]> {
      get { __data["labelIds"] }
      set { __data["labelIds"] = newValue }
    }

    /// The identifier or key of the team associated with the issue.
    var teamId: String {
      get { __data["teamId"] }
      set { __data["teamId"] = newValue }
    }

    /// The cycle associated with the issue.
    var cycleId: GraphQLNullable<String> {
      get { __data["cycleId"] }
      set { __data["cycleId"] = newValue }
    }

    /// The project associated with the issue.
    var projectId: GraphQLNullable<String> {
      get { __data["projectId"] }
      set { __data["projectId"] = newValue }
    }

    /// The project milestone associated with the issue.
    var projectMilestoneId: GraphQLNullable<String> {
      get { __data["projectMilestoneId"] }
      set { __data["projectMilestoneId"] = newValue }
    }

    /// The team state of the issue.
    var stateId: GraphQLNullable<String> {
      get { __data["stateId"] }
      set { __data["stateId"] = newValue }
    }

    /// The comment the issue is referencing.
    var referenceCommentId: GraphQLNullable<String> {
      get { __data["referenceCommentId"] }
      set { __data["referenceCommentId"] = newValue }
    }

    /// The position of the issue in its column on the board view.
    var boardOrder: GraphQLNullable<Double> {
      get { __data["boardOrder"] }
      set { __data["boardOrder"] = newValue }
    }

    /// The position of the issue related to other issues.
    var sortOrder: GraphQLNullable<Double> {
      get { __data["sortOrder"] }
      set { __data["sortOrder"] = newValue }
    }

    /// The position of the issue in parent's sub-issue list.
    var subIssueSortOrder: GraphQLNullable<Double> {
      get { __data["subIssueSortOrder"] }
      set { __data["subIssueSortOrder"] = newValue }
    }

    /// The date at which the issue is due.
    var dueDate: GraphQLNullable<TimelessDate> {
      get { __data["dueDate"] }
      set { __data["dueDate"] = newValue }
    }

    /// Create issue as a user with the provided name. This option is only available to OAuth applications creating issues in `actor=application` mode.
    var createAsUser: GraphQLNullable<String> {
      get { __data["createAsUser"] }
      set { __data["createAsUser"] = newValue }
    }

    /// Provide an external user avatar URL. Can only be used in conjunction with the `createAsUser` options. This option is only available to OAuth applications creating comments in `actor=application` mode.
    var displayIconUrl: GraphQLNullable<String> {
      get { __data["displayIconUrl"] }
      set { __data["displayIconUrl"] = newValue }
    }

    /// Whether the passed sort order should be preserved
    var preserveSortOrderOnCreate: GraphQLNullable<Bool> {
      get { __data["preserveSortOrderOnCreate"] }
      set { __data["preserveSortOrderOnCreate"] = newValue }
    }

    /// The date when the issue was created (e.g. if importing from another system). Must be a date in the past. If none is provided, the backend will generate the time as now.
    var createdAt: GraphQLNullable<DateTime> {
      get { __data["createdAt"] }
      set { __data["createdAt"] = newValue }
    }

    /// [Internal] The timestamp at which an issue will be considered in breach of SLA.
    var slaBreachesAt: GraphQLNullable<DateTime> {
      get { __data["slaBreachesAt"] }
      set { __data["slaBreachesAt"] = newValue }
    }

    /// The identifier of a template the issue should be created from. If other values are provided in the input, they will override template values.
    var templateId: GraphQLNullable<String> {
      get { __data["templateId"] }
      set { __data["templateId"] = newValue }
    }
  }

}