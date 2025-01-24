# cs8803 - iOS Firebase Photo Sharing App

This is a sample iOS application built with **SwiftUI** and **Firebase**, demonstrating basic features of:

- User Authentication (Firebase Auth)
- Basic Profile Management
- Sign In / Sign Up Flows
- Tab-based UI
- Friend system
- Photo Sharing (Feed)

## Features Overview

### Profile Management

- Users can update their display name and upload an avatar.
- Avatars are uploaded to Cloudinary, and their URL is saved in Firestore.
- Users can manually set their location via text input.

### Feed

- Displays posts shared by the user and their accepted friends.
- Shows the poster's name, image, caption, and timestamp.
- Posts are fetched in real-time from Firestore.

### Friend System

- Users can send, accept, and reject friend requests.
- Only accepted friends and the user themselves can view posts in the feed.

### Post Creation

- Users can upload a photo and write a caption.
- Photos are uploaded to Cloudinary, and their metadata is stored in Firestore.

## Requirements

- Xcode 14+ (Swift 5.7+)
- iOS 16+ deployment target
- CocoaPods for dependency management

## Setup

1. Clone or download this repository.
2. Run `pod install` in the root directory.
3. Open `cs8803.xcworkspace` by running `open cs8803.xcworkspace` in the Terminal at the `cs8803` folder.
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

- Add real-time comment functionality
- Implement social login (Google, Facebook)
- Add location-based features
- Introduce notifications for likes, comments, and friend requests

## Credits

- Cloudinary: API Usage to upload and store photos
