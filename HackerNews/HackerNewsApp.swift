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
            RootView()
        }
    }
}

private struct RootView: View {
    @State private var safariItem: SafariItem?

    var body: some View {
        ContentView()
            .withRouter(\.router)
            .environment(\.openURL, OpenURLAction { url in
                safariItem = SafariItem(url: url)
                return .handled
            })
            .sheet(item: $safariItem) { item in
                SafariView(url: item.url)
                    .ignoresSafeArea()
            }
    }
}

private struct SafariItem: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}
