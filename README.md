# PocketLLM

<div align="center">
  <img src="assets/Logo.png" alt="PocketLLM Logo" width="200"/>
  <h3>A Modern Flutter-based Chat Application with LLM Integration</h3>
</div>

PocketLLM is a sophisticated Flutter-based chat application that harnesses the power of large language models to deliver intelligent conversational experiences. Built with modern architecture and best practices, it offers a seamless cross-platform solution for AI-powered conversations.

## 📱 App Screenshots

<div align="center">
  <img src="assets/mockups/splash_screen.jpg" alt="Splash Screen" width="250"/>
  <img src="assets/mockups/chat.jpg" alt="Chat Interface" width="250"/>
  <img src="assets/mockups/model_library.jpg" alt="Model Library" width="250"/>
</div>

## ✨ Features

- 🤖 Interactive chat interface with AI-powered responses
- 🔐 Secure authentication system powered by Supabase
- 📁 Advanced file handling and image picking capabilities
- ✍️ Rich text formatting with Markdown support
- ⚙️ Customizable settings and configurations
- 🌐 Cross-platform support (Android, iOS, Web)
- 🎨 Modern and intuitive user interface
- 🔄 Real-time message synchronization

## 🛠️ Tech Stack

- **Frontend Framework**: Flutter 3.27.4
- **Programming Language**: Dart 3.6.2
- **Backend Services**: Supabase
- **State Management**: Provider
- **Authentication**: Supabase Auth
- **Storage**: Supabase Storage
- **UI Components**: Material Design

## 📋 Prerequisites

Before you begin, ensure you have met the following requirements:

- Flutter SDK (3.27.4 or later)
- Dart SDK (3.6.2 or later)
- Java Development Kit (JDK) 17 or later
- Android Studio / VS Code with Flutter extensions
- A Supabase account for backend services
- Git for version control

## 📦 Dependencies

Key packages used in this project:

```yaml
dependencies:
  flutter_svg: ^2.0.7        # SVG rendering
  image_picker: ^1.0.4       # Image selection
  animated_text_kit: ^4.2.3  # Text animations
  flutter_markdown: ^0.6.0   # Markdown rendering
  supabase_flutter: ^1.10.25 # Supabase integration
  flutter_secure_storage: ^9.0.0 # Secure storage
```

For a complete list of dependencies, check the `pubspec.yaml` file.

## 🚀 Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/pocketllm.git
   cd pocketllm
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a new project in Supabase
   - Copy your project URL and anon key
   - Update the configuration in `lib/services/auth_service.dart`

4. **Run the application**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── component/       # Core UI components
│   ├── appbar/     # Custom app bar components
│   ├── chat_interface.dart
│   └── sidebar.dart
├── pages/          # Application screens
│   ├── auth/      # Authentication related pages
│   └── settings/  # Settings pages
├── services/       # Business logic and API services
│   ├── auth_service.dart
│   └── termux_service.dart
└── widgets/        # Reusable UI widgets
```

## 🤝 Contributing

We welcome contributions to PocketLLM! Here's how you can help:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

Please read our [Contributing Guidelines](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 🔒 Security

If you discover any security-related issues, please email security@pocketllm.com instead of using the issue tracker. All security vulnerabilities will be promptly addressed.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 💬 Support

For support and questions:
- Open an issue in the repository
- Join our [Discord community](https://discord.gg/pocketllm)
- Follow us on [Twitter](https://twitter.com/pocketllm)

## 🙏 Acknowledgments

- Thanks to all contributors who have helped shape PocketLLM
- Special thanks to the Flutter and Supabase teams for their amazing frameworks
- Icons and design resources from [Flutter Material Design](https://material.io/design)

---

<div align="center">
Made with ❤️ by the PocketLLM Team
</div>