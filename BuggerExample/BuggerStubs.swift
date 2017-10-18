//
//  BuggerStubs.swift
//  BuggerExample
//
//  Created by Kyle McAlpine on 14/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import Foundation
import OHHTTPStubs

struct BuggerStubs {
    static func configureStubs(loadingTime: TimeInterval = 1) {
        stub(condition: { _ -> Bool in return true }) { _ -> OHHTTPStubsResponse in
            fatalError()
        }
        
        stub(condition: isHost("api.github.com")) { _ -> OHHTTPStubsResponse in
            let json = [
                "id": 1,
                "url": "https://api.github.com/repos/octocat/Hello-World/issues/1347",
                "repository_url": "https://api.github.com/repos/octocat/Hello-World",
                "labels_url": "https://api.github.com/repos/octocat/Hello-World/issues/1347/labels{/name}",
                "comments_url": "https://api.github.com/repos/octocat/Hello-World/issues/1347/comments",
                "events_url": "https://api.github.com/repos/octocat/Hello-World/issues/1347/events",
                "html_url": "https://github.com/octocat/Hello-World/issues/1347",
                "number": 1347,
                "state": "open",
                "title": "Found a bug",
                "body": "I'm having a problem with this.",
                "user": [
                    "login": "octocat",
                    "id": 1,
                    "avatar_url": "https://github.com/images/error/octocat_happy.gif",
                    "gravatar_id": "",
                    "url": "https://api.github.com/users/octocat",
                    "html_url": "https://github.com/octocat",
                    "followers_url": "https://api.github.com/users/octocat/followers",
                    "following_url": "https://api.github.com/users/octocat/following{/other_user}",
                    "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
                    "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
                    "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
                    "organizations_url": "https://api.github.com/users/octocat/orgs",
                    "repos_url": "https://api.github.com/users/octocat/repos",
                    "events_url": "https://api.github.com/users/octocat/events{/privacy}",
                    "received_events_url": "https://api.github.com/users/octocat/received_events",
                    "type": "User",
                    "site_admin": false
                ],
                "labels": [
                [
                "id": 208045946,
                "url": "https://api.github.com/repos/octocat/Hello-World/labels/bug",
                "name": "bug",
                "color": "f29513",
                "default": true
                ]
                ],
                "assignee": [
                    "login": "octocat",
                    "id": 1,
                    "avatar_url": "https://github.com/images/error/octocat_happy.gif",
                    "gravatar_id": "",
                    "url": "https://api.github.com/users/octocat",
                    "html_url": "https://github.com/octocat",
                    "followers_url": "https://api.github.com/users/octocat/followers",
                    "following_url": "https://api.github.com/users/octocat/following{/other_user}",
                    "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
                    "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
                    "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
                    "organizations_url": "https://api.github.com/users/octocat/orgs",
                    "repos_url": "https://api.github.com/users/octocat/repos",
                    "events_url": "https://api.github.com/users/octocat/events{/privacy}",
                    "received_events_url": "https://api.github.com/users/octocat/received_events",
                    "type": "User",
                    "site_admin": false
                ],
                "milestone": [
                    "url": "https://api.github.com/repos/octocat/Hello-World/milestones/1",
                    "html_url": "https://github.com/octocat/Hello-World/milestones/v1.0",
                    "labels_url": "https://api.github.com/repos/octocat/Hello-World/milestones/1/labels",
                    "id": 1002604,
                    "number": 1,
                    "state": "open",
                    "title": "v1.0",
                    "description": "Tracking milestone for version 1.0",
                    "creator": [
                        "login": "octocat",
                        "id": 1,
                        "avatar_url": "https://github.com/images/error/octocat_happy.gif",
                        "gravatar_id": "",
                        "url": "https://api.github.com/users/octocat",
                        "html_url": "https://github.com/octocat",
                        "followers_url": "https://api.github.com/users/octocat/followers",
                        "following_url": "https://api.github.com/users/octocat/following{/other_user}",
                        "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
                        "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
                        "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
                        "organizations_url": "https://api.github.com/users/octocat/orgs",
                        "repos_url": "https://api.github.com/users/octocat/repos",
                        "events_url": "https://api.github.com/users/octocat/events{/privacy}",
                        "received_events_url": "https://api.github.com/users/octocat/received_events",
                        "type": "User",
                        "site_admin": false
                    ],
                    "open_issues": 4,
                    "closed_issues": 8,
                    "created_at": "2011-04-10T20:09:31Z",
                    "updated_at": "2014-03-03T18:58:10Z",
                    "closed_at": "2013-02-12T13:22:01Z",
                    "due_on": "2012-10-09T23:39:01Z"
                ],
                "locked": false,
                "comments": 0,
                "pull_request": [
                    "url": "https://api.github.com/repos/octocat/Hello-World/pulls/1347",
                    "html_url": "https://github.com/octocat/Hello-World/pull/1347",
                    "diff_url": "https://github.com/octocat/Hello-World/pull/1347.diff",
                    "patch_url": "https://github.com/octocat/Hello-World/pull/1347.patch"
                ],
                "closed_at": nil,
                "created_at": "2011-04-22T13:33:48Z",
                "updated_at": "2011-04-22T13:33:48Z",
                "closed_by": [
                    "login": "octocat",
                    "id": 1,
                    "avatar_url": "https://github.com/images/error/octocat_happy.gif",
                    "gravatar_id": "",
                    "url": "https://api.github.com/users/octocat",
                    "html_url": "https://github.com/octocat",
                    "followers_url": "https://api.github.com/users/octocat/followers",
                    "following_url": "https://api.github.com/users/octocat/following{/other_user}",
                    "gists_url": "https://api.github.com/users/octocat/gists{/gist_id}",
                    "starred_url": "https://api.github.com/users/octocat/starred{/owner}{/repo}",
                    "subscriptions_url": "https://api.github.com/users/octocat/subscriptions",
                    "organizations_url": "https://api.github.com/users/octocat/orgs",
                    "repos_url": "https://api.github.com/users/octocat/repos",
                    "events_url": "https://api.github.com/users/octocat/events{/privacy}",
                    "received_events_url": "https://api.github.com/users/octocat/received_events",
                    "type": "User",
                    "site_admin": false
                ]
                ] as [String : Any?]
            let data = try! JSONSerialization.data(withJSONObject: json, options: [])
            let response = OHHTTPStubsResponse(data: data, statusCode: 201, headers: nil)
            response.requestTime = loadingTime
            return response
        }
        
        stub(condition: isHost("api.imgur.com")) { request -> OHHTTPStubsResponse in
            let json = [
                "data": [
                    "id": "B9RLNcN",
                    "title": nil,
                    "description": nil,
                    "datetime": 1508002975,
                    "type": "image/png",
                    "animated": false,
                    "width": 400,
                    "height": 400,
                    "size": 144276,
                    "views": 0,
                    "bandwidth": 0,
                    "vote": nil,
                    "favorite": false,
                    "nsfw": nil,
                    "section": nil,
                    "account_url": nil,
                    "account_id": 0,
                    "is_ad": false,
                    "in_most_viral": false,
                    "has_sound": false,
                    "tags": [],
                    "ad_type": 0,
                    "ad_url": "",
                    "in_gallery": false,
                    "deletehash": "4eLUSkeWRgTsQ0Z",
                    "name": "",
                    "link": "https://i.imgur.com/B9RLNcN.png"
                ],
                "success": true,
                "status": 200
            ] as [String : Any]
            let data = try! JSONSerialization.data(withJSONObject: json, options: [])
            let response = OHHTTPStubsResponse(data: data, statusCode: 200, headers: nil)
            response.requestTime = loadingTime
            return response
        }
    }
}
