// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

protocol LinearGraphQL_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == LinearGraphQL.SchemaMetadata {}

protocol LinearGraphQL_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == LinearGraphQL.SchemaMetadata {}

protocol LinearGraphQL_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == LinearGraphQL.SchemaMetadata {}

protocol LinearGraphQL_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == LinearGraphQL.SchemaMetadata {}

extension LinearGraphQL {
  typealias ID = String

  typealias SelectionSet = LinearGraphQL_SelectionSet

  typealias InlineFragment = LinearGraphQL_InlineFragment

  typealias MutableSelectionSet = LinearGraphQL_MutableSelectionSet

  typealias MutableInlineFragment = LinearGraphQL_MutableInlineFragment

  enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    static let configuration: ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    static func objectType(forTypename typename: String) -> Object? {
      switch typename {
      case "Mutation": return LinearGraphQL.Objects.Mutation
      case "IssuePayload": return LinearGraphQL.Objects.IssuePayload
      case "Issue": return LinearGraphQL.Objects.Issue
      case "ApiKey": return LinearGraphQL.Objects.ApiKey
      case "IntegrationTemplate": return LinearGraphQL.Objects.IntegrationTemplate
      case "Integration": return LinearGraphQL.Objects.Integration
      case "WorkflowState": return LinearGraphQL.Objects.WorkflowState
      case "IssueImport": return LinearGraphQL.Objects.IssueImport
      case "Cycle": return LinearGraphQL.Objects.Cycle
      case "IssueLabel": return LinearGraphQL.Objects.IssueLabel
      case "Project": return LinearGraphQL.Objects.Project
      case "IssueDraft": return LinearGraphQL.Objects.IssueDraft
      case "Team": return LinearGraphQL.Objects.Team
      case "User": return LinearGraphQL.Objects.User
      case "OauthClient": return LinearGraphQL.Objects.OauthClient
      case "Attachment": return LinearGraphQL.Objects.Attachment
      case "AuditEntry": return LinearGraphQL.Objects.AuditEntry
      case "ProjectUpdate": return LinearGraphQL.Objects.ProjectUpdate
      case "Reaction": return LinearGraphQL.Objects.Reaction
      case "Comment": return LinearGraphQL.Objects.Comment
      case "Company": return LinearGraphQL.Objects.Company
      case "CustomView": return LinearGraphQL.Objects.CustomView
      case "Document": return LinearGraphQL.Objects.Document
      case "DocumentContent": return LinearGraphQL.Objects.DocumentContent
      case "Emoji": return LinearGraphQL.Objects.Emoji
      case "ExternalUser": return LinearGraphQL.Objects.ExternalUser
      case "Favorite": return LinearGraphQL.Objects.Favorite
      case "RoadmapToProject": return LinearGraphQL.Objects.RoadmapToProject
      case "Roadmap": return LinearGraphQL.Objects.Roadmap
      case "IntegrationsSettings": return LinearGraphQL.Objects.IntegrationsSettings
      case "IssueHistory": return LinearGraphQL.Objects.IssueHistory
      case "IssueRelation": return LinearGraphQL.Objects.IssueRelation
      case "OauthClientApproval": return LinearGraphQL.Objects.OauthClientApproval
      case "Template": return LinearGraphQL.Objects.Template
      case "Organization": return LinearGraphQL.Objects.Organization
      case "OrganizationDomain": return LinearGraphQL.Objects.OrganizationDomain
      case "OrganizationInvite": return LinearGraphQL.Objects.OrganizationInvite
      case "ProjectMilestone": return LinearGraphQL.Objects.ProjectMilestone
      case "ProjectLink": return LinearGraphQL.Objects.ProjectLink
      case "ProjectUpdateInteraction": return LinearGraphQL.Objects.ProjectUpdateInteraction
      case "PushSubscription": return LinearGraphQL.Objects.PushSubscription
      case "PaidSubscription": return LinearGraphQL.Objects.PaidSubscription
      case "TeamMembership": return LinearGraphQL.Objects.TeamMembership
      case "FirstResponderSchedule": return LinearGraphQL.Objects.FirstResponderSchedule
      case "UserSettings": return LinearGraphQL.Objects.UserSettings
      case "ViewPreferences": return LinearGraphQL.Objects.ViewPreferences
      case "Webhook": return LinearGraphQL.Objects.Webhook
      case "WorkflowCronJobDefinition": return LinearGraphQL.Objects.WorkflowCronJobDefinition
      case "WorkflowDefinition": return LinearGraphQL.Objects.WorkflowDefinition
      case "IssueSearchResult": return LinearGraphQL.Objects.IssueSearchResult
      case "DocumentSearchResult": return LinearGraphQL.Objects.DocumentSearchResult
      case "ProjectSearchResult": return LinearGraphQL.Objects.ProjectSearchResult
      case "IssueNotification": return LinearGraphQL.Objects.IssueNotification
      case "ProjectNotification": return LinearGraphQL.Objects.ProjectNotification
      case "OauthClientApprovalNotification": return LinearGraphQL.Objects.OauthClientApprovalNotification
      case "CustomViewNotificationSubscription": return LinearGraphQL.Objects.CustomViewNotificationSubscription
      case "CycleNotificationSubscription": return LinearGraphQL.Objects.CycleNotificationSubscription
      case "LabelNotificationSubscription": return LinearGraphQL.Objects.LabelNotificationSubscription
      case "ProjectNotificationSubscription": return LinearGraphQL.Objects.ProjectNotificationSubscription
      case "TeamNotificationSubscription": return LinearGraphQL.Objects.TeamNotificationSubscription
      case "UserNotificationSubscription": return LinearGraphQL.Objects.UserNotificationSubscription
      default: return nil
      }
    }
  }

  enum Objects {}
  enum Interfaces {}
  enum Unions {}

}