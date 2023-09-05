//
//  File.swift
//  
//
//  Created by Kyle Satti on 9/3/23.
//

import Foundation
import PackagePlugin

@main
struct ToomasKitPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let outputDir = context.pluginWorkDirectory.appending("LinearGraphQL")
        let config = apolloConfig(path: outputDir.string)
        return [
            .buildCommand(
                displayName: "Linear GraphQL Codegen",
                executable: try context.tool(named: "apollo-ios-cli").path,
                arguments: ["generate", "-s", config],
                outputFiles: [outputDir]
            )
        ]
    }

    func apolloConfig(path: String) -> String {
        return """
        {
          "schemaNamespace" : "LinearGraphQL",
          "input" : {
            "operationSearchPaths" : [
              "**/*.graphql"
            ],
            "schemaSearchPaths" : [
              "**/*.graphqls"
            ]
          },
          "output" : {
            "testMocks" : {
              "none" : {
              }
            },
            "schemaTypes" : {
              "path" : "\(path)",
              "moduleType" : {
                "embeddedInTarget" : {
                  "name" : "LinearGraphQL"
                }
              }
            },
            "operations" : {
              "inSchemaModule" : {
              }
            }
          }
        }

        """
    }
}
