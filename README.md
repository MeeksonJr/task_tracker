# Collaborative Task Tracker

A collaborative task management mobile app built with Flutter, Firebase, and Riverpod. Designed for teams to assign tasks, track deadlines, comment in real time, attach images, receive due date reminder notifications, and detect public holidays.

---

## Features

- **Authentication & Roles**
  - Email and password authentication via Firebase Auth.
  - Role-based permissions (`Admin` and `Member`).
  - Admins and task creators have management access to edit and delete tasks.

- **Task Management (CRUD & Filters)**
  - Real-time synchronization with Cloud Firestore.
  - Segmented views: **My Tasks**, **Assigned by Me**, and **Completed**.
  - Priority levels: Low, Medium, High, and Urgent (color-coded).
  - Search by task title, description, or assignee name.
  - Priority filter chips and one-tap task completion toggle.

- **Comments & Activity Audit Trail**
  - Real-time comment threads on every task.
  - Automated activity history tracking actions: task created, status changed, updated, and comments posted.

- **Image Attachments & Permissions**
  - Attach images using the camera or photo gallery via `image_picker`.
  - Android runtime permission handling with fallback dialog to app settings.
  - Persistent local file storage in the app documents directory.
  - Thumbnail preview strip and interactive full-screen viewer with pinch-to-zoom.

- **Notifications & Due Date Reminders**
  - Local scheduled notifications powered by `flutter_local_notifications` and `timezone`.
  - Automatically schedules notification alarms at task due dates.
  - Cancels scheduled notifications when a task is completed or deleted.
  - Includes a "Send Test Reminder" button in task details to test notification delivery instantly.

- **Public Holiday Awareness (External REST API)**
  - Integrated with the [Nager.Date v3 Public Holidays API](https://date.nager.at/Api) using `dio`.
  - Automatically checks if a selected due date lands on an official US public holiday.
  - Displays a warning banner in the task form when scheduling.
  - Shows public holiday badges on task cards and detail views.
  - In-memory cache by year to minimize network calls and support offline usage.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart 3) |
| State Management | Riverpod 3.x (`Notifier`, `StreamProvider`, `Provider`) |
| Backend & Database | Firebase Authentication, Cloud Firestore |
| REST API Client | Dio |
| Notifications | `flutter_local_notifications`, `timezone` |
| Media & Permissions | `image_picker`, `permission_handler` |
| Local File Storage | `path_provider`, `path` |
| Testing | `flutter_test` |

---

## Project Structure

```
lib/
├── main.dart                      # App entry point & service initialization
├── firebase_options.dart          # Firebase platform configuration
├── models/
│   ├── activity_model.dart        # Task activity log model
│   ├── comment_model.dart         # Comment thread model
│   ├── holiday_model.dart         # Public holiday model (Nager.Date)
│   ├── task_model.dart            # Task model with priority, status, holiday
│   └── user_model.dart            # User profile model & roles
├── providers/
│   ├── attachment_provider.dart   # Attachment upload notifier
│   ├── auth_provider.dart         # Auth state & user profile stream
│   ├── comment_provider.dart      # Real-time comment streams & actions
│   ├── holiday_provider.dart      # Holiday service & lookup providers
│   ├── notification_provider.dart # Notification service provider
│   └── task_provider.dart         # Task streams, tab state, filters, controller
├── screens/
│   ├── auth/                      # Login, Register, AuthGate screens
│   ├── dashboard/                 # Main dashboard with tabs & search
│   └── tasks/
│       ├── task_detail_screen.dart# Task details, comments, activity, attachments
│       ├── task_form_screen.dart  # Create/edit task form with holiday notice
│       └── widgets/
│           ├── task_card.dart     # Task card widget with badges
│           └── user_avatar.dart   # User avatar component
├── services/
│   ├── attachment_service.dart    # Saves attachments to app documents
│   ├── auth_service.dart          # Firebase Auth operations
│   ├── comment_service.dart       # Firestore comment operations
│   ├── holiday_service.dart       # Dio Nager.Date API client with caching
│   ├── notification_service.dart  # Local notification scheduler
│   └── task_service.dart          # Firestore task & activity operations
└── utils/
    └── image_picker_helper.dart   # Permission checks & bottom sheet picker
```

---

## Database Schema (Firestore)

- **`users/{userId}`**
  - `email`: string
  - `displayName`: string
  - `role`: string (`Admin` | `Member`)
  - `photoUrl`: string?
  - `createdAt`: timestamp

- **`tasks/{taskId}`**
  - `title`: string
  - `description`: string
  - `priority`: string (`low` | `medium` | `high` | `urgent`)
  - `status`: string (`todo` | `inProgress` | `completed`)
  - `dueDate`: timestamp
  - `creatorId`: string
  - `creatorName`: string
  - `assigneeId`: string
  - `assigneeName`: string
  - `attachmentUrls`: array of strings (local file paths)
  - `holidayName`: string?
  - `createdAt`: timestamp
  - `updatedAt`: timestamp

  - **Subcollection: `tasks/{taskId}/comments/{commentId}`**
    - `authorId`: string
    - `authorName`: string
    - `content`: string
    - `createdAt`: timestamp

  - **Subcollection: `tasks/{taskId}/activities/{activityId}`**
    - `taskId`: string
    - `userId`: string
    - `userName`: string
    - `type`: string (`created` | `statusChanged` | `assigned` | `updated` | `commentAdded`)
    - `details`: string
    - `timestamp`: timestamp

---

## Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- Android device or emulator with Developer Mode and USB debugging enabled.
- A Firebase project with Email/Password Auth and Cloud Firestore enabled.

### 2. Setup
1. Clone the repository:
   ```bash
   git clone <repo-url>
   cd task_tracker
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Ensure `google-services.json` is located in `android/app/` (already configured for this project).

### 3. Run the App
Connect your Android device or start an emulator, then run:
```bash
flutter run
```

### 4. Run Tests & Code Analysis
```bash
# Run unit and model tests
flutter test

# Run Dart static analysis
dart analyze .
```

---

## Key Architecture Decisions & Tradeoffs

1. **Local Persistent Storage for Attachments vs. Cloud Storage**
   - Firebase Storage requires an upgraded Blaze (pay-as-you-go) plan, which blocks usage on free/academic tiers.
   - To keep the app functional without billing, images are copied into the app's persistent documents directory (`path_provider`) and their file paths are stored in Firestore.
   - Both local files and remote URLs are supported seamlessly by the UI components.

2. **Riverpod 3.x with Notifiers**
   - The app uses modern `Notifier<T>` and `NotifierProvider` classes instead of legacy `StateNotifier`.
   - Providers cleanly separate presentation from business logic and database streams.

3. **In-Memory Caching for Public Holidays**
   - Nager.Date holiday data is fetched per year and cached in `HolidayService`.
   - Subsequent checks when browsing tasks or picking dates are instant and do not trigger extra network requests.

4. **Exact Alarms & Notification Fallback**
   - The app requests `SCHEDULE_EXACT_ALARM` and `USE_EXACT_ALARM` permissions for precise deadline reminders.
   - If exact alarms are restricted by the device's battery saver or OS policy, the scheduler gracefully falls back to `inexactAllowWhileIdle`.
