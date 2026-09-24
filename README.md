# Maha Maintain Pro — Sprint 1 (Foundation)

Enterprise CRM + Field Service Management platform. This scaffold covers
Sprint 1 of Phase 1: project architecture, Firebase wiring, authentication
(email + mobile OTP), role-based access, secure storage, theming, routing,
and reusable UI components.

## What's included

- **Feature-first architecture** — `lib/features/<feature>/{data,presentation}`,
  shared code in `lib/core/`
- **State management** — Riverpod (`flutter_riverpod`)
- **Routing** — `go_router` with auth + permission-based redirect guards
- **Auth** — Email/password and mobile OTP via Firebase Auth
- **Role-based access** — 6 roles (Super Admin, Admin, Sales Manager, Sales
  Executive, Technician, Customer) with a central `PermissionService`
  mirrored server-side in `firestore.rules`
- **Secure storage** — `flutter_secure_storage` wrapper for tokens/session
- **Theme & reusable widgets** — buttons, text fields, cards, role badges,
  empty states, loading indicators
- **Placeholder screens** — Leads, Customers, Societies, Service Requests,
  User Management routes are wired but show "coming soon" until their
  sprint (2–4) is built, so navigation doesn't need rework later

## Setup

### 1. Install Flutter dependencies
```bash
flutter pub get
```

### 2. Firebase setup
This scaffold ships with a **placeholder** `lib/firebase_options.dart` so
the project compiles out of the box, but it will not actually connect to
Firebase until you replace it:

```bash
# Install the CLI tools if you don't have them
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# Log in and create/select a Firebase project at https://console.firebase.google.com
firebase login

# Generate real firebase_options.dart for this project
flutterfire configure
```

Then in the Firebase Console, enable:
- **Authentication** → Sign-in methods: Email/Password, and Phone
- **Firestore Database** (start in production mode)
- **Storage** (for file attachments / photos in later sprints)

Deploy the included security rules:
```bash
firebase deploy --only firestore:rules
```

### 3. Run
```bash
flutter run
```

## Roles & permissions

Roles live in `lib/features/role_access/models/user_role.dart`. The
allowed-actions matrix lives in
`lib/features/role_access/services/permission_service.dart` — this is the
**only** place role → permission mapping should be edited. Never inline a
role check (`if (user.role == UserRole.admin)`) in a screen; call
`PermissionService.can(role, Permission.x)` instead.

`firestore.rules` mirrors this matrix server-side. Client-side checks are
for UX (hiding buttons/routes); the Firestore rules are the actual
enforcement layer — keep both in sync when access changes.

New self-registered accounts default to `customer` and must be promoted
by a Super Admin/Admin via the User Management screen (Sprint 2+).

## Next up (Sprint 2 — CRM)

Lead dashboard, add/edit/delete lead, Kanban pipeline, follow-up
scheduler, lead timeline, search/filters, assignment, file attachments.
The `leads` route and drawer entry are already wired to a placeholder —
Sprint 2 replaces `ComingSoonScreen` with the real feature.
