# Repository Guidelines

## Architecture Overview
- **Platform**: Native SwiftUI application targeting iOS 26+, leaning on structured concurrency and observable state for predictable updates.

## Project Structure & Module Organization
The root hosts `HackerNews.xcodeproj` plus Swift sources under `HackerNews/`, with entry points in `HackerNewsApp.swift`. As the code base grows, introduce sibling folders (`App/`, `Models/`, `Services/`, `Utilities/`, `Views/`, `Tests/`) within `HackerNews/`. Keep assets in `HackerNews/Assets.xcassets` and park preview scaffolding under dedicated `Previews/` groups.

## Routing
For routing inside the app, we use https://github.com/n3d1117/Routing (dependency already imported). Read usage at /Users/ned/Developer/Runtime/README.md

## Coding Style & Naming Conventions
Prefer concise, tidy, comment-free Swift that stays production ready. Use four-space indentation, `UpperCamelCase` types, and `lowerCamelCase` members. Keep view structs focused, extract subviews quickly, and rely on naming and structure—not inline commentary—to communicate intent. Minimize SwiftUI redraws and optimize for efficiency and smooth scrolling.

For iOS 18+ use the new Observation model: prefer `@Observable` types and `@State` view models; avoid `@StateObject`, `@Published`, and `@ObservedObject`.

## Testing Guidelines
Adopt the latest `Swift Testing` framework for unit tests.
