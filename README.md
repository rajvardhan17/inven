# inven

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

```bash
lib/
 ┣ main.dart

 ┣ screens/                  # All UI pages
 ┃ ┣ auth/
 ┃ ┃ ┣ login_screen.dart
 ┃ ┃ ┗ register_screen.dart
 ┃ ┃
 ┃ ┣ dashboard/
 ┃ ┃ ┗ admin_home.dart
 ┃ ┃
 ┃ ┣ inventory/
 ┃ ┃ ┣ inventory_screen.dart
 ┃ ┃ ┗ add_product_screen.dart
 ┃ ┃
 ┃ ┗ splash/
 ┃   ┗ splash_screen.dart   # (optional but useful)

 ┣ widgets/                 # Reusable UI components
 ┃ ┣ custom_button.dart
 ┃ ┣ custom_textfield.dart
 ┃ ┗ stat_card.dart

 ┣ models/                  # Data models
 ┃ ┗ product_model.dart

 ┣ services/                # API / backend logic
 ┃ ┣ api_service.dart
 ┃ ┗ auth_service.dart

 ┣ utils/                   # Helpers / constants
 ┃ ┣ colors.dart
 ┃ ┗ validators.dart
 ```