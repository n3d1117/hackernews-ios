<img src="https://github.com/user-attachments/assets/2da628a1-44d2-462d-b653-5e35c1617e8b" height=130>

# HackerNews
[![ios-version](https://img.shields.io/badge/iOS-18+-blue.svg)](https://developer.apple.com/ios/)
[![xcode-version](https://img.shields.io/badge/Xcode-16+-blue.svg)](https://developer.apple.com/xcode/)

Personal SwiftUI toy project used to experiment with:
- iOS 26 design language experiments
- SwiftUI MeshGradient-based soft backgrounds
- The excellent [MarkdownUI](https://github.com/gonzalezreal/MarkdownUI) rendering (for comments)
- SwiftUI zoom transitions with matched sources
- Deep link handling (`hn://` + pasting HN URLs in-app)
- Dependency injection via `AppDependencies` + environment keys
- iOS 26 navigation subtitle

## Screenshots
| Home | Story |
| --- | --- |
| ![Home](https://github.com/user-attachments/assets/4be80a72-546f-4bdf-b8f8-6b98d45f1441) | ![Story](https://github.com/user-attachments/assets/36eae89e-7474-470c-99a0-48dcc921d7e6) |

## Backend
The backend implementation is not included. The app is wired to a private API; update the base URL in `HackerNews/Services/HackerNewsAPI.swift` to point at your own service.

## Requirements
- iOS 18.0 or later (but designed with iOS 26 in mind)
- Xcode 16 or later

## Getting Started
1. Clone the repository and open `HackerNews.xcodeproj`.
2. Update the backend settings in `HackerNews/Services/HackerNewsAPI.swift`.
3. Run on a simulator or device.

## Testing
Tests use Swift Testing. Run them from Xcode or with `xcodebuild test`.
