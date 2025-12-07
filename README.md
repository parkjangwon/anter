# Anter: Intelligent SSH Client

Anter is a modern, cross-platform SSH client built with Flutter, designed for developers and system administrators who need a robust, efficient, and intelligent terminal experience. It combines a beautiful UI with powerful features like session recording, AI-powered command assistance, and smart backup capabilities.

![Anter Header](https://raw.githubusercontent.com/parkjw/anter/main/assets/readme_header.png)

## Key Features 🚀

### 1. Modern & Responsive Terminal

- **Cross-Platform:** Runs seamlessly on macOS, Windows, Linux, Android, and iOS.
- **Beautiful UI:** Clean, intuitive interface with support for dark mode and customizable themes.
- **Tab Management:** Efficiently manage multiple SSH sessions with a browser-like tab system.
- **Split View:** Support for split-pane terminal views for multitasking.

### 2. Session Recording & Playback 🎥

- **Automatic Recording:** Option to automatically record all terminal sessions for audit and review.
- **Replay:** Built-in player to watch past sessions exactly as they happened, with timeline navigation.
- **Export:** Export individual recording files for sharing or archiving.

### 3. AI Assistant (Gemini) 🤖

- **Smart Command Generation:** Integrated Google Gemini AI to generate Linux commands from natural language queries.
- **Context-Aware:** Ask questions like "Check disk space" or "Find large files" and get the exact command to run.
- **Safe Execution:** Generated commands are presented for review before execution.

### 4. Backup & Restore ☁️

- **Backup:** Quickly backup your sessions, settings, and shortcuts into a portable JSON file.
- **Restore:** Intelligent restoration logic that prevents duplicate sessions.
- **Cross-Device:** Easily move your configuration between your computer and mobile device.

### 5. Advanced SSH Features 🔐

- **Key Authentication:** Support for PEM, PPK, and OpenSSH keys.
- **Login Scripts:** Automate post-login tasks with custom script execution.
- **SFTP Support:** Built-in SFTP client for easy file transfer.
- **Smart Tunneling:** Easily set up port forwarding tunnels.

## Getting Started

### Prerequisites

- Flutter SDK (Latest Stable)
- Dart SDK

### Installation

1.  **Clone the repository**

    ```bash
    git clone https://github.com/parkjw/anter.git
    cd anter
    ```

2.  **Install dependencies**

    ```bash
    flutter pub get
    ```

3.  **Run the app**

    ```bash
    # For macOS
    flutter run -d macos

    # For Android
    flutter run -d android
    ```

## Architecture

Anter follows a clean architecture principle using **Riverpod** for state management and **Drift** for local persistence.

- `lib/src/features`: Feature-based modules (Session, Terminal, Settings, etc.).
- `lib/src/core`: Core utilities, database configuration, and shared widgets.
- `lib/src/shared`: Shared UI components and helpers.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
