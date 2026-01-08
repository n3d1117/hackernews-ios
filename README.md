<img src="https://github.com/user-attachments/assets/2da628a1-44d2-462d-b653-5e35c1617e8b" height=130>

# HackerNews
[![ios-version](https://img.shields.io/badge/iOS-26+-blue.svg)](https://developer.apple.com/ios/)
[![xcode-version](https://img.shields.io/badge/Xcode-26+-blue.svg)](https://developer.apple.com/xcode/)

Personal SwiftUI toy project used to experiment with:
- OpenAI's Codex for agentic coding (exploring ideas + prototype implementation)
- iOS 26 design language
- SwiftUI MeshGradient-based soft backgrounds
- The _excellent_ [MarkdownUI](https://github.com/gonzalezreal/MarkdownUI) and [swift-readability](https://github.com/Ryu0118/swift-readability) libraries
- SwiftUI zoom transitions with matched sources
- Deep link handling (`hn://` + pasting HN URLs in-app)
- Dependency injection via `AppDependencies` + environment keys
- iOS 26 navigation subtitle
- Offline, on-device story summaries using Apple Intelligence (FoundationModels)

## Screenshots
| Home | Story | AI Summary |
| --- | --- | --- |
| ![Home](https://github.com/user-attachments/assets/83966d8a-9fe7-4a2d-8cbc-f866a3b8ffdd) | ![Story](https://github.com/user-attachments/assets/03da4ae7-94f7-482c-b197-97123022a7f4) | ![AI Summary](https://github.com/user-attachments/assets/5483ea29-93d8-4d5e-b059-a0fadc313d31) |

## Backend
The backend implementation is not included. The app is wired to a private API; update the base URL in `HackerNews/Services/HackerNewsAPI.swift` to point at your own service.

## Requirements
- iOS 26.0 or later
- Xcode 26 or later

## Getting Started
1. Clone the repository and open `HackerNews.xcodeproj`.
2. Update the backend settings in `HackerNews/Services/HackerNewsAPI.swift`.
3. Run on a simulator or device.

## Testing
Tests use Swift Testing. Run them from Xcode or with `xcodebuild test`.
