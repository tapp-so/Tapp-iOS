# Tapp iOS SDK

> Official iOS package for integrating **Tapp** attribution & referral tracking into your app.

<p align="center">
  <a href="https://github.com/tapp-so/Tapp-iOS"><img alt="GitHub stars" src="https://img.shields.io/github/stars/tapp-so/Tapp-iOS?style=social"></a>
  <a href="https://github.com/tapp-so/Tapp-iOS/releases"><img alt="GitHub release" src="https://img.shields.io/github/v/release/tapp-so/Tapp-iOS"></a>
  <a href="https://github.com/tapp-so/Tapp-iOS/blob/main/LICENSE.md"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-green.svg"></a>
</p>

## Overview

**Tapp iOS SDK** provides the client-side building blocks for **mobile app attribution** and **affiliate/referral tracking**. Use it to:

* Track installs and sessions
* Attribute conversions to campaigns, partners, and referral sources
* Handle referral links and deep links
* Record custom events with metadata

This repository contains the Swift package and testing targets used across Tapp-powered apps.

## Features

* ✅ Swift Package with CocoaPods spec
* 🔗 Deep link & universal link handling helpers
* 🧭 Install/session lifecycle tracking primitives
* 🧮 Lightweight analytics event API
* 🔧 Environment/config management via plist or in-code

## Requirements

* **Xcode**: 15+ (recommended)
* **Swift**: 5.9+
* **Platforms**: iOS 13+ (recommended). Check `Package.swift` for the authoritative minimums.

> If you need older platform support, open an issue with your target versions and use case.

## Installation

### Swift Package Manager

Add **Tapp-iOS** directly from GitHub:

1. In Xcode, go to **File → Add Packages…**

2. Enter the repository URL:

   ```text
   https://github.com/tapp-so/Tapp-iOS.git
   ```

3. Choose the latest version tag.

4. Add the **Tapp** product to your app target.

Or in `Package.swift`:

```swift
.dependencies: [
    .package(url: "https://github.com/tapp-so/Tapp-iOS.git", from: "1.0.91")
]
```

## Quick Start

1. **Import and configure** in your `AppDelegate` (or `SceneDelegate` if preferred):

```swift
import Tapp
import TappNetworking

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let configuration = TappConfiguration(authToken: <TAPP_AUTH_TOKEN>,
                                              env: .sandbox,
                                              tappToken: <TAPP_TOKEN>,
                                              affiliate: .tapp)
        Tapp.start(config: configuration,
                   delegate: self)
        return true
    }
}
```

> The exact API surface may evolve; see inline docs and source for available calls.

## Deep Links & Deferred Links

Forward open URL / user activity to Tapp so referrals can be attributed correctly on deep links.

**Scene-based apps (iOS 13+):**

```swift
func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    if let url = userActivity.referrerURL, Tapp.shouldProcess(url: url) {
        Tapp.fetchLinkData(for: url) { result in
            switch result {
            case .success(let linkData):
                //Process the link data
            case .failure(let error):
                //Handle error
            }
        }
    }
}

func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    let tappContexts = URLContexts.filter { Tapp.shouldProcess(url: $0.url) }
    tappContexts.forEach { context in
        Tapp.fetchLinkData(for: context.url) { result in
            switch result {
            case .success(let linkData):
                //Process the link data
            case .failure(let error):
                //Handle error
            }
        }
    }
}
```

**AppDelegate-based apps:**

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if Tapp.shouldProcess(url: url) {
            Tapp.fetchLinkData(for: url) { result in
                switch result {
                case .success(let linkData):
                //Process the link data
                case .failure(let error):
                //Handle error
            }
        }
    }

    return true
}

func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                 restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    if let url = userActivity.referrerURL, Tapp.shouldProcess(url: url) {
        Tapp.fetchLinkData(for: url) { result in
            switch result {
            case .success(let linkData):
                //Process the link data
            case .failure(let error):
                //Handle error
            }
        }
    }
    return true
}
```

## Retrieving origin link data

At any point in the app's lifecycle you can retrieve the referrer's link data (if any)

```swift

Tapp.fetchOriginLinkData { result in
        switch result {
        case .success(let linkData):
        break
        case .failure(let error):
        break
    }
}
```

## Attribution & Events

Use a simple, flexible event API to record user actions and revenue.

```swift

//Register a predefined Tapp event. We provide a comprehensive list of the most app-related events.

Tapp.handleTappEvent(event: TappEvent(eventAction: .completeRegistration))

//Register a custom Tapp event.

Tapp.handleTappEvent(event: TappEvent(eventAction: .custom("CUSTOM_EVENT_NAME")))

```

## Versioning

We follow semantic versioning. See [Releases](https://github.com/tapp-so/Tapp-iOS/releases) for notes and pinned tags.

## License

MIT © Tapp — see [LICENSE.md](LICENSE.md).
