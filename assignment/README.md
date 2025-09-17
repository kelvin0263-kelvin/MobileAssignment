# Mechanic Hub (Flutter)

Mechanic Hub is a Flutter application for mechanics to manage daily jobs, track time, add notes/photos, and sign off completed work. This repo contains a self‑contained demo that uses mock data and local storage, so it runs without a backend.

## Features

- Jobs dashboard with day/week view and status tabs (On Hold, In Progress, Completed)
- Job details with overview, time tracking, parts, and notes tabs
- Start/pause/stop timer per job
- Notes with optional image path, customer details, and requested services
- Basic authentication with mock user stored via `shared_preferences`

## Tech stack

- Flutter 3.x, Dart 3.x
- State management: `provider`
- Local storage: `shared_preferences`

## Project structure

- `lib/main.dart`: App entry and theme
- `lib/providers/`: `AuthProvider`, `JobProvider`
- `lib/services/`: `AuthService` (mock), `JobService` (mock jobs, search, status updates)
- `lib/models/`: `job.dart`, `user.dart`, `question.dart`
- `lib/screens/`: `dashboard`, `task`, `search`, `profile`, `job_details`, `login`, etc.
- `lib/widgets/`: UI components (header, bottom nav, job cards, notes/timer/signature widgets)
- `lib/utils/app_utils.dart`: Theme, colors, text styles, helpers

## Getting started

1) Install Flutter: see the Flutter docs.

2) Fetch packages:

```bash
flutter pub get
```

3) Run the app (choose one):

```bash
flutter run -d chrome      # web
flutter run -d windows     # windows desktop
flutter run -d android     # emulator/physical device
flutter run -d ios         # macOS + Xcode required
```

## Mock login

- Username: `mechanic`
- Password: `password`

## Notes

- Data is mocked in `JobService` and `AuthService`. Replace with real APIs by swapping implementations.
- Some additional widgets exist for future use (e.g., badges/cards). Keep or remove depending on your needs.

## Scripts

Run static analysis and formatting:

```bash
flutter analyze
dart format .
```
