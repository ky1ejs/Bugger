//
//  demoApp.swift
//  demo
//
//  Created by Fabio Milano on 2/16/26.
//

import SwiftUI
import Bugger

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                BuggerScreen(bugger: .onDevice)
                    .navigationTitle("Bugger")
            }
        }
    }
}
