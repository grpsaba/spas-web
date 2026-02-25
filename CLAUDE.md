# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common commands

```bash
# Install dependencies
flutter pub get

# Run locally (web)
flutter run -d chrome

# Static analysis / lint
flutter analyze

# Tests
flutter test
flutter test test/widget_test.dart
flutter test test/widget_test.dart --plain-name "Counter increments smoke test"

# Build + deploy web
flutter build web
firebase use spas-cd4c9
firebase deploy --only hosting
```

Notes:
- Firebase Hosting serves `build/web` and rewrites all routes to `index.html` (`firebase.json`).
- This repo currently tracks generated web output files in `build/web/` and `.firebase/hosting.*.cache`; when preparing a deploy, rebuild web assets before deploying.

## High-level architecture

### App bootstrap and shell
- Entry point: `lib/main.dart`.
  - Initializes Firebase using `DefaultFirebaseOptions.currentPlatform`.
  - Uses `setPathUrlStrategy()` for hashless web URLs.
  - Registers app-level providers via `MultiProvider` (`HomeProvider`, `SpeechProvider`, `ErrorLogProvider`).
- App root uses `MaterialApp.router` with GoRouter config from `lib/router.dart`.
- Most pages are wrapped in `PageModel` (`lib/administration/home.dart`), which provides the shared app bar + animated side drawer.
- Drawer/menu definitions are centralized in `lib/models/menu_item_model.dart`.

### Routing and auth flow
- Routing is centralized in `lib/router.dart` with a large GoRouter tree.
- `initialLocation` is `/home`.
- Auth gate is implemented in router `redirect`: most routes require `AuthService.currentManager`, loaded via `AuthService().authState()`.
- Public exceptions include `/login`, `/error`, and agent search/folder routes (`/agents/recherche`, `/agents/dossier`).

### State management pattern
- Primary state management is `provider` + `ChangeNotifier`.
- Global/shared providers are mounted in `main.dart`.
- Feature-specific providers are often created at page level (e.g., zone pointage modern page creates `PointageZoneProvider` in `lib/zone/pointage_zone_list_modern.dart`).

### Data layer and backend integration
- Backend is Firebase (Auth + Firestore + Hosting).
- Firestore access is mostly through service classes in `lib/services/` (e.g., `site.dart`, `supervisor.dart`, `manager.dart`, `pointer*.dart`), each tied to a collection.
- Core domain models are consolidated in `lib/model.dart` (large shared model file).
- Key collection names used in services: `Managers`, `Sites`, `Supervisors`, `ZoneMembers`, `Zones`, `Agents`, `Tools`, `Notes`, `CheckLists`, `sitePointings`, `agentPointings`, `zonePointings`, `rondierPointings`, `toolPointings`, `locationTracker`.

## Feature map (big picture)

- Dashboard/home: `lib/accueil/`
  - Main page: `home_page.dart`
  - Home-level state: `lib/providers/home_provider.dart`
- CRUD/admin domains: `lib/site/`, `lib/supervisor/`, `lib/agent/`, `lib/manager/`, `lib/zone/`, `lib/zone_member/`, `lib/tools/`, `lib/department/`, `lib/agent_type/`, `lib/categorieTools/`
- Legacy pointage screens/reports:
  - `lib/pointage_site/`, `lib/pointage_agent/`, `lib/zone/pointage_zone_list.dart`
  - Export/PDF logic in `lib/services/export.dart` and `lib/pdf/api/pdf_api.dart`
- New pointage redesign architecture: `lib/pointage_redesign/`
  - `data/` repositories + cache manager
  - `models/` filter/pagination/stats/exception types
  - `providers/` state orchestration
  - `presentation/` widgets + design system
- Error log monitoring module: `lib/error_logs/`
  - Firestore-backed provider with filtering, pagination, bulk resolve, and stats.

## Repo-specific constraints and gotchas

- Web-first project:
  - `lib/firebase_options.dart` only defines web Firebase options.
  - Multiple files rely on web APIs (`dart:html`/`universal_html`) for PDF/export flows.
- `lib/generated/assets.dart` is generated (`DO NOT EDIT` in file header).
- Zone pointage has both legacy and redesigned flows; router currently points `/pointagezones` to `PointageZoneListModern`.
- `lib/pointage_redesign/data/pointage_zone_repository.dart` documents required Firestore composite indexes for `zonePointings`; missing indexes surface as query errors.
- README is boilerplate and does not document project-specific architecture; rely on the code paths above.
