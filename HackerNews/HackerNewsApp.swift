//
//  HackerNewsApp.swift
//  HackerNews
//
//  Created by ned on 17/10/25.
//

import SwiftUI
import Routing

@main
struct HackerNewsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withRouter(\.router)
        }
    }
}
