# Repository Guidelines

## Architecture Overview
- **Platform**: Native SwiftUI application targeting iOS 26+, leaning on structured concurrency and observable state for predictable updates.

## Project Structure & Module Organization
The root hosts `HackerNews.xcodeproj` plus Swift sources under `Sports/`, with entry points in `HackerNewsApp.swift`. As the code base grows, introduce sibling folders (`App/`, `Models/`, `Services/`, `Utilities/`, `Views/`, `Tests/`) within `HackerNews/`. Keep assets in `Sports/Assets.xcassets` and park preview scaffolding under dedicated `Previews/` groups.

## Routing
For routing inside the app, we use https://github.com/n3d1117/Routing (dependency already imported). Read usage at /Users/ned/Developer/Runtime/README.md

## Build, Test, and Development Commands
- Always use XcodeBuildMCP server to build the project, and always do so when making code changes, to ensure your code compiles. Always use iPhone 17 Pro simulator.

## Coding Style & Naming Conventions
Prefer concise, tidy, comment-free Swift that stays production ready. Use four-space indentation, `UpperCamelCase` types, and `lowerCamelCase` members. Keep view structs focused, extract subviews quickly, and rely on naming and structure—not inline commentary—to communicate intent. Minimize SwiftUI redraws and optimize for efficiency and smooth scrolling.

For iOS 18+ use the new Observation model: prefer `@Observable` types and `@State` view models; avoid `@StateObject`, `@Published`, and `@ObservedObject`.

## Testing Guidelines
Adopt the latest `Swift Testing` framework for unit tests.

## Commit & Pull Request Guidelines
Write imperative commit subjects ≤72 characters (e.g., `Introduce standings pager`) with optional scope in parentheses.

## Security & Configuration Tips
Never commit API keys, signing assets, or `.xcconfig` secrets. Document required environment variables in `README` tables, ship placeholder `.xcconfig.example` files, and lean on Xcode-managed signing or encrypted CI variables for live credentials. Keep AGENTS.md file updated when new instructions arise.

## Additional documentation
For topics like Liquid Glass design (iOS 26), Foundation Models (iOS 26), and other Apple-specific stuff, also consult the .md files at `/Applications/Xcode-26.1.1.app/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/AdditionalDocumentation/`
