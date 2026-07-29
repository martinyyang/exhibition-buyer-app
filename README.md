# Exhibition Buyer App

A Flutter-based mobile and web application for exhibition buyers to manage events, booths, photos, and annotations with real-time collaboration features.

## Features

- **Event Management**: Create and manage exhibition events
- **Booth Organization**: Track and organize exhibition booths
- **Photo Management**: Upload and view booth photos in grid layout
- **Photo Annotation**: Add colored flags to photos for marking items of interest
- **Team Collaboration**: Multi-buyer support with color-coded identification
- **Real-time Sync**: Live updates across team members using Supabase Realtime
- **Multi-language**: Supports English and Chinese (中文)
- **Responsive Design**: Works on mobile, tablet, and web browsers

## Tech Stack

- **Frontend**: Flutter 3.24.5 / Dart 3.5.4
- **State Management**: Riverpod
- **Backend**: Supabase (PostgreSQL + Realtime + Storage)
- **Authentication**: Supabase Auth
- **Testing**: flutter_test, mocktail

## Test Coverage

- **121 tests passing (100%)**
  - 36 unit tests
  - 80 widget tests
  - 5 integration tests

See [TEST_COMPLETION_REPORT_FINAL.md](docs/TEST_COMPLETION_REPORT_FINAL.md) and [INTEGRATION_TEST_COMPLETION.md](docs/INTEGRATION_TEST_COMPLETION.md) for details.

## Prerequisites

- Flutter SDK 3.24.5 or higher
- Dart 3.5.4 or higher
- A Supabase account and project

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/martinyyang/exhibition-buyer-app.git
cd exhibition-buyer-app
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure Supabase

Create a `.env` file in the project root (copy from `.env.example`):

```bash
cp .env.example .env
```

Edit `.env` and add your Supabase credentials:

```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### 4. Set up Supabase database

Run the SQL scripts in the `supabase/sql/` directory in your Supabase SQL Editor:

1. `COMPLETE_SETUP.sql` - Creates all tables, RLS policies, and triggers
2. (Optional) Manual steps documented in `supabase/sql/MANUAL_STEPS.md`

### 5. Run the app

**Web:**
```bash
flutter run -d chrome
```

**Mobile (iOS/Android):**
```bash
flutter run
```

**Build release APK:**
```bash
flutter build apk --release
```

## Testing

Run all tests:
```bash
flutter test
```

Run specific test suites:
```bash
flutter test test/unit          # Unit tests only
flutter test test/widget        # Widget tests only
flutter test test/integration   # Integration tests only
```

## Project Structure

```
lib/
├── core/              # Core functionality (routing, services, providers)
├── features/          # Feature modules
│   ├── auth/          # Authentication
│   ├── event/         # Event management
│   ├── booth/         # Booth management
│   ├── photo/         # Photo upload and viewing
│   └── flag/          # Photo annotation
├── shared/            # Shared widgets and utilities
└── main.dart          # App entry point

test/
├── unit/              # Unit tests
├── widget/            # Widget tests
└── integration/       # Integration tests

supabase/sql/          # Database setup scripts
```

## Database Schema

The app uses PostgreSQL with Row Level Security (RLS) enabled for data isolation between teams:

- `teams` - Organization teams
- `users` - User accounts with team association
- `events` - Exhibition events
- `booths` - Exhibition booths
- `photos` - Booth photos
- `flags` - Photo annotations

See `supabase/sql/COMPLETE_SETUP.sql` for the complete schema.

## Documentation

- [Test Completion Report](docs/TEST_COMPLETION_REPORT_FINAL.md)
- [Integration Test Completion](docs/INTEGRATION_TEST_COMPLETION.md)
- [Manual Test Checklist](docs/manual_test_checklist.md)
- [Emulator Setup Guide](docs/emulator_setup.md)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

## Support

For issues and questions, please open an issue on GitHub.
