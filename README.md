# Connevo - Connect & Communicate

Connevo is a modern, high-performance mobile communication platform built with Flutter. It provides users with a seamless experience for real-time messaging, group collaborations, and high-quality video/audio calling.

## 🚀 Key Features

### 1. Real-time Messaging
- **One-on-One Chat:** Direct and secure private messaging.
- **Group Chats:** Create groups and communicate with multiple people simultaneously.
- **Typing Indicators:** See when your contacts are typing in real-time.
- **Message Seen Status:** Track when your messages have been read.

### 2. Rich Media Sharing
- **Image Sharing:** High-quality image transmission with optimized gallery picking.
- **Document Support:** Send and receive PDFs, Word docs, Excel sheets, and more.
- **File Management:** Built-in file type icons for easy identification of documents.

### 3. Video & Audio Calls
- **High-Definition Video:** Crystal clear video calling powered by ZegoCloud.
- **Voice Calls:** Standard audio calling for quick conversations.
- **Call Permissions:** Robust handling of camera and microphone access.

### 4. User Profile & Discovery
- **Personalized Profiles:** Update your display name and profile picture.
- **Presence Tracking:** Real-time online/offline status and "Last Seen" indicators.
- **User Search:** Easily find and start conversations with new contacts.

### 5. Advanced UI/UX
- **Unified Branding:** Beautifully integrated logo watermarks across all screens.
- **Animated Splash Screen:** Professional "Spin and Pop-in" entry animation with a 3-second progress indicator.
- **Branded AppBars:** Consistent primary color styling with transparency effects.
- **Launcher Icons:** Custom-designed adaptive launcher icons for Android and iOS.

## 🛠 Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Flutter Riverpod
- **Backend:** Firebase (Auth, Firestore, Cloud Messaging)
- **Media Hosting:** ImgBB (Optimized profile picture hosting)
- **Calling Engine:** ZegoCloud UIKit
- **Animations:** Flutter AnimatedBuilder & Transitions

## 📦 Installation & Setup

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/bolajidavid25/Connevo.git
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Firebase Setup:**
    - Ensure you have the FlutterFire CLI installed.
    - Run `flutterfire configure` to sync your local environment with your Firebase project.
4.  **ZegoCloud Setup:**
    - Obtain your `AppID` and `AppSign` from the [ZegoCloud Admin Console](https://console.zegocloud.com/).
    - Replace the credentials in `lib/chat/screen/chat_room_screen.dart`.
5.  **Run the application:**
    ```bash
    flutter run
    ```

## 📱 Screenshots & Branding

The app features a clean white UI with the **Connevo Primary Blue (#1A237E)** used for highlights, buttons, and AppBars. A subtle 5% opacity logo watermark is present on all screens to reinforce the brand identity.

---
Developed by **Bolaji David**
