# cs8803 - iOS Firebase Photo Sharing App

This is a sample iOS application built with **SwiftUI** and **Firebase**, demonstrating basic features of:

- User Authentication (Firebase Auth)
- Basic Profile Management
- Sign In / Sign Up Flows
- Tab-based UI
- Friend system

## Requirements

- Xcode 14+ (Swift 5.7+)
- iOS 16+ deployment target
- CocoaPods for dependency management

## Setup

1. Clone or download this repository.
2. Run `pod install` in the root directory.
3. Open `cs8803.xcworkspace`, by running `open cs8803.xcworkspace` in the Terminal at the `cs8803` folder.
4. Make sure you have a valid `GoogleService-Info.plist` (from the [Firebase Console](https://console.firebase.google.com)).
   - Feel free to replace the existing `GoogleService-Info.plist` with your own. This has [my](https://github.com/ethanyanyan) credentials loaded.
5. Build and run on a simulator or real device.

## Usage

1. **Launch** the app.
2. **Sign Up** or **Login** with an email and password.
3. **Home Tab** will appear once you're logged in, offering:
   - **Feed** (view posts)
   - **Post** (upload a new photo)
   - **Profile** (edit profile, sign out)

## Roadmap

- Add photo sharing functionality
- Add real-time feeds
- Allow commenting and viewing of only friend's comments
- Implement social login (Google, Facebook)
- Add location-based features

## Credits

- Cloudinary: API Usage to upload and store photos
