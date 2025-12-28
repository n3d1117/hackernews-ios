# Repository Guidelines

## Architecture Overview
- **Platform**: Native SwiftUI application targeting iOS 26+, leaning on structured concurrency and observable state for predictable updates.

## Project Structure & Module Organization
The root hosts `HackerNews.xcodeproj` plus Swift sources under `HackerNews/`, with entry points in `App/HackerNewsApp.swift` and `App/AppRootView.swift`. As the code base grows, introduce sibling folders (`App/`, `Models/`, `Services/`, `Utilities/`, `ViewModels/`, `Views/`, `Tests/`) within `HackerNews/`. Keep assets in `HackerNews/Assets.xcassets` and park preview scaffolding under dedicated `Previews/` groups.

## Routing
For routing inside the app, we use https://github.com/n3d1117/Routing (dependency already imported)

## Coding Style & Naming Conventions
Prefer concise, tidy, comment-free Swift that stays production ready. Use four-space indentation, `UpperCamelCase` types, and `lowerCamelCase` members. Keep view structs focused, extract subviews quickly, and rely on naming and structure—not inline commentary—to communicate intent. Minimize SwiftUI redraws and optimize for efficiency and smooth scrolling. Favor standalone view structs over computed `some View` vars when breaking out subviews to help SwiftUI diffing.

For iOS 18+ use the new Observation model: prefer `@Observable` types and `@State` view models; avoid `@StateObject`, `@Published`, and `@ObservedObject`.

Use `@ObservationIgnored` for non-observed stored properties in observable types (e.g., services/encoders), and pass dependencies via `AppDependencies` + `@Entry` environment keys in `AppEnvironmentKeys.swift` (router, cardNamespace, storyService, bookmarksStore, seenStoriesStore) instead of singletons.

Decode URLs directly as `URL` using `decodeLossyURL` (see `Utilities/KeyedDecodingContainer+LossyURL.swift`) instead of manual string mapping.

Primary screens: `HomeFeedView` with `StoryFeedViewModel`, and `PostDetailView` with `PostDetailViewModel` + decomposed subviews. Deep linking is handled by `DeepLinkCoordinator` in `App/`.

## Testing Guidelines
Adopt the latest `Swift Testing` framework for unit tests.
