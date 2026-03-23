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
│
├── core/                          🔥 (GLOBAL चीजें)
│   ├── constants/
│   │   ├── colors.dart
│   │   ├── strings.dart
│   │
│   ├── utils/
│   │   ├── helpers.dart
│   │   ├── validators.dart
│   │
│   ├── widgets/                  🔥 reusable UI
│   │   ├── custom_button.dart
│   │   ├── custom_textfield.dart
│   │   ├── alert_banner.dart
│
│
├── models/                        🔥 ALL MODELS HERE
│   ├── raw_material_model.dart
│   ├── product_model.dart
│   ├── production_model.dart
│   ├── recipe_model.dart
│   ├── order_model.dart
│   ├── shop_model.dart
│   ├── user_model.dart
│   ├── stock_alert_model.dart
│
│
├── services/                      🔥 BUSINESS LOGIC
│   ├── inventory_service.dart
│   ├── production_service.dart
│   ├── order_service.dart
│   ├── payment_service.dart
│   ├── auth_service.dart
│
│
├── data/                          🔥 TEMP / LOCAL STORAGE
│   ├── app_data.dart
│
│
├── modules/                       🔥 FEATURE BASED STRUCTURE
│
│   ├── admin/
│   │   ├── dashboard/
│   │   │   └── admin_dashboard.dart
│   │   │
│   │   ├── inventory/
│   │   │   ├── inventory_screen.dart
│   │   │   ├── add_product_screen.dart
│   │   │
│   │   ├── production/
│   │   │   ├── production_screen.dart
│   │   │   ├── production_history_screen.dart
│   │   │
│   │   ├── orders/
│   │   │   ├── orders_screen.dart
│   │   │   ├── order_detail_screen.dart
│   │   │
│   │   ├── payments/
│   │   │   ├── payments_screen.dart
│   │   │
│   │   ├── users/
│   │   │   ├── salesman_screen.dart
│   │   │   ├── distributor_screen.dart
│   │   │
│
│   ├── salesman/
│   │   ├── home/
│   │   │   └── salesman_home.dart
│   │   ├── shops/
│   │   │   ├── add_shop_screen.dart
│   │   │   ├── shop_list_screen.dart
│   │   ├── orders/
│   │   │   ├── create_order_screen.dart
│
│   ├── distributor/
│   │   ├── home/
│   │   │   └── distributor_home.dart
│   │   ├── delivery/
│   │   │   ├── delivery_list_screen.dart
│   │   │   ├── payment_collection_screen.dart
│
│
├── routes/                        🔥 NAVIGATION
│   ├── app_routes.dart
│
│
├── main.dart
```
