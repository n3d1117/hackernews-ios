import Observation
import Routing
import SwiftUI

// Hosts the navigation stack and wires deep linking to the router.
struct AppRootView: View {
    @Environment(\.router) private var router
    @Bindable private var coordinator: DeepLinkCoordinator
    private let api: HackerNewsAPI

    init(dependencies: AppDependencies) {
        self._coordinator = Bindable(wrappedValue: dependencies.coordinator)
        self.api = dependencies.api
    }

    init(coordinator: DeepLinkCoordinator, api: HackerNewsAPI) {
        self._coordinator = Bindable(wrappedValue: coordinator)
        self.api = api
    }

    var body: some View {
        HomeFeedView(service: api)
            .sheet(item: $coordinator.safariItem) { item in
                SafariView(url: item.url)
            }
            .onAppear {
                coordinator.attach(router: router)
            }
            .onOpenURL { url in
                _ = coordinator.open(url)
            }
    }
}
