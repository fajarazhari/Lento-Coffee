# Lento Coffee POS — Flutter Application

Production-ready Flutter POS application with Firebase backend.

## Stack
- **Framework**: Flutter 3.x
- **State Management**: Riverpod 2 (code-generated)
- **Navigation**: GoRouter 14
- **Backend**: Firebase (Auth · Firestore · Storage · Messaging)
- **Offline Cache**: Hive
- **Architecture**: Feature-first, clean architecture

---

## Project Structure

```
lib/
├── main.dart              # Entry point
├── firebase_options.dart  # Firebase config (REPLACE with your config)
├── app/                   # Root app, router, theme
├── core/                  # Constants, errors, utils, services
├── shared/                # Reusable widgets, models
└── features/
    ├── auth/              # Firebase Auth, PIN, employee switch
    ├── pos/               # Dashboard POS, cart
    ├── products/          # Menu catalog, variants, addons
    ├── transactions/      # Order history, order model
    ├── payments/          # Payment processing
    ├── inventory/         # Ingredients, stock deduction
    ├── shift/             # Cashier shift management
    ├── kitchen/           # KDS barista queue
    ├── customer_display/  # Customer board (full-screen)
    ├── reports/           # Sales analytics
    ├── loyalty/           # Points, tiers, vouchers
    └── settings/          # App config, employees, audit logs
```

---

## Quick Start

### 1. Prerequisites

```bash
# Install Flutter (3.22+)
# https://docs.flutter.dev/get-started/install/windows

# Verify installation
flutter --version
flutter doctor
```

### 2. Firebase Setup

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Create project at console.firebase.google.com
# Project ID: lento-coffee-prod

# Configure (auto-generates firebase_options.dart)
flutterfire configure --project=lento-coffee-prod
```

### 3. Enable Firebase Services (Firebase Console)

- **Authentication** → Email/Password (enable)
- **Firestore** → Create database, region: `asia-southeast2` (Jakarta)
- **Storage** → Create bucket

### 4. Deploy Firestore Rules & Indexes

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

### 5. Install Dependencies & Run

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

---

## Code Generation

This project uses Riverpod Generator. After any change to providers:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
# or watch mode during development:
flutter pub run build_runner watch
```

Generated files (`*.g.dart`) are excluded from git.

---

## User Roles

| Role | Access |
|------|--------|
| **Owner** | Full access to all features |
| **Manager** | All except Settings write |
| **Cashier** | POS, Transactions, Shift |
| **Barista** | KDS only |

---

## Firestore Collections

| Collection | Purpose |
|---|---|
| `users` | Employee profiles + roles |
| `products` + `products/{id}/variants` | Menu catalog |
| `addons` | Extra items |
| `ingredients` | Inventory stock levels |
| `recipes` | Ingredient → product mapping |
| `orders` + `orders/{id}/items` | POS transactions |
| `payments` | Payment records |
| `shifts` + `shifts/{id}/cash_transactions` | Shift management |
| `inventory_logs` | Immutable stock movement log |
| `loyalty_accounts` | Customer loyalty |
| `audit_logs` | Security event log |
| `settings` | Store configuration |

---

## Development Notes

### Adding a new feature
1. Create `lib/features/{name}/` folder
2. Follow the pattern: `data/models/` → `data/repositories/` → `domain/` → `presentation/`
3. Add provider with `@riverpod` annotation
4. Register route in `lib/app/router.dart`
5. Run `build_runner`

### Offline Mode
- Cart state persisted in Hive on every change
- Draft orders queued locally if offline
- Firestore SDK handles read caching automatically
- `ConnectivityService` drives the offline banner in POS shell

### Testing
```bash
flutter test
flutter test integration_test/
```

---

## Firebase Cloud Functions

Located in `functions/` (Node.js TypeScript):

| Function | Trigger |
|---|---|
| `onOrderPaid` | Deducts inventory on payment confirmation |
| `onShiftClose` | Generates daily revenue summary |

Deploy:
```bash
cd functions && npm install
firebase deploy --only functions
```

---

*Lento Coffee POS v1.0 — Built with Flutter + Firebase*
