# Connevo | Premium Real-Time Communication Platform

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase&logoColor=ffca28)](https://firebase.google.com/)
[![Riverpod](https://img.shields.io/badge/Riverpod-blue?style=for-the-badge&logo=riverpod&logoColor=white)](https://riverpod.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

Connevo is a high-performance, cross-platform communication ecosystem built with **Flutter**. Engineered for speed, security, and scalability, Connevo provides a seamless bridge for modern digital interaction through real-time messaging and high-fidelity video/audio synthesis.

---

## 💎 Core Architecture & Features

### 📡 Real-Time Synchronous Communication
*   **Direct & Persistent Messaging**: Ultra-low latency chat powered by Firebase Firestore.
*   **Intelligent Group Clusters**: dynamic group management with real-time participation updates.
*   **State-Driven UI**: Live typing indicators and atomic "Seen" status updates for enhanced user feedback.

### 🎥 Enterprise-Grade AV Calling
*   **WebRTC Integration**: High-definition, low-latency video and audio calling via ZegoCloud SDK.
*   **Adaptive Bitrate**: Automatic quality adjustment based on network conditions for uninterrupted connectivity.

### 📂 Multimedia & Document Transmission
*   **Binary Content Support**: Seamless sharing of images and documents (PDF, DOCX, XLSX, etc.).
*   **Optimized Edge Storage**: Integration with high-speed CDNs for media retrieval and profile synchronization.

### 🎨 Human-Centric UI/UX
*   **Custom Animation Engine**: Bespoke "Spin-Pop" entry sequence and smooth material transitions.
*   **Branded Experience**: Unified branding with a subtle 5% alpha watermark and consistent primary palette (`#1A237E`).
*   **Adaptive Environment**: Full support for iOS and Android design paradigms, including adaptive launcher icons.

---

## 🛠 Strategic Technical Stack

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Frontend** | Flutter SDK (Dart) | Multi-platform UI execution |
| **State** | Riverpod | Scalable, compile-safe state management |
| **Backend** | Firebase | Auth, NoSQL DB, & Cloud Messaging |
| **Calling** | ZegoCloud UIKit | WebRTC wrapper for video/audio engine |
| **Storage** | ImgBB / Firebase | Optimized media hosting |

---

## 🚀 Deployment Pipeline

### Prerequisites
- Flutter SDK (Latest Stable)
- Java 17+
- Android Studio / VS Code
- FlutterFire CLI

### Local Setup
1.  **Initialize Environment**:
    ```bash
    git clone https://github.com/bolajidavid25/Connevo.git
    cd Connevo
    flutter pub get
    ```

2.  **Firebase Handshake**:
    ```bash
    flutterfire configure --project=connevo
    ```

3.  **Engine Credentials**:
    Configure `appID` and `appSign` in `lib/chat/screen/chat_room_screen.dart` using your [ZegoCloud Dashboard](https://console.zegocloud.com/) credentials.

4.  **Execute**:
    ```bash
    flutter run
    ```

---

## 📈 System Security & Optimization
*   **ProGuard Obfuscation**: Custom rules implemented to protect SDK integrity.
*   **Memory Management**: Optimized JVM arguments to ensure high performance on low-RAM devices.
*   **Permission Orchestration**: Native-level handling for Camera, Microphone, and Storage access.

---

## 👨‍💻 Engineering Leadership
Developed and maintained by **Bolaji David**.

*Project developed with an emphasis on SOLID principles and clean architecture.*
