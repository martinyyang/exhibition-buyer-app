# Exhibition Buyer Collaboration Platform

A Flutter-based web platform for exhibition buyers and remote team members to manage events, booths, photos, and annotations with real-time collaboration features.

> 💡 **Project Focus**: Web platform with mobile browser support. Native mobile apps are not currently in development.

## Features

- **Event Management**: Create and manage exhibition events
- **Booth Organization**: Track and organize exhibition booths
- **Photo Management**: WebP format upload with real-time progress tracking (5x faster than JPEG)
- **Photo Annotation**: Add crosshair flags with zoom controls and purchase status tracking
- **Team Collaboration**: Multi-buyer and remote member support with real-time sync
- **Price Conversion**: Custom formula calculator for converted pricing
- **China Network Optimization**: Cloudflare Workers proxy support for improved connectivity
- **Performance Optimized**: 60-80% smaller photos, 1-3s upload on 3G networks
- **Multi-language**: Supports English and Chinese (中文)
- **Responsive Design**: Mobile web browsers with touch/zoom support

## Tech Stack

- **Frontend**: Flutter 3.24.5 / Dart 3.5.4
- **State Management**: Riverpod
- **Backend**: Supabase (PostgreSQL + Realtime + Storage)
- **Authentication**: Supabase Auth
- **Deployment**: Cloudflare Pages (automatic deployment from GitHub)
- **Testing**: flutter_test, mocktail

## Test Coverage

Comprehensive test suite with unit, widget, and integration tests covering core features.

See [docs/TEST_COMPLETION_REPORT_FINAL.md](docs/TEST_COMPLETION_REPORT_FINAL.md) for details.

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

# Optional: Cloudflare Workers proxy for China network optimization
# SUPABASE_PROXY_URL=https://your-worker.workers.dev
```

See [docs/CLOUDFLARE_PROXY_SETUP.md](docs/CLOUDFLARE_PROXY_SETUP.md) for proxy configuration.

## Deployment

### Production Deployment (Cloudflare Pages)

The application is deployed on Cloudflare Pages with automatic deployment from GitHub:

- **Production URL**: `https://exhibition-buyer-app.pages.dev`
- **Auto-deploy**: Every push to `main` branch triggers deployment
- **Environment Variables**: Configured in Cloudflare Pages dashboard (not in `.env`)

For deployment setup and configuration, see [docs/CLOUDFLARE_PAGES_DEPLOYMENT.md](docs/CLOUDFLARE_PAGES_DEPLOYMENT.md).

### Local Development

For local development, use the `.env` file as described in step 3 above.

### 4. Set up Supabase database

Run the SQL setup script in your Supabase SQL Editor:

1. Navigate to your Supabase project → SQL Editor
2. Execute `docs/COMPLETE_SETUP.sql` - Creates all tables, RLS policies, and triggers
3. Set up Storage bucket: `photos` (public, 2MB limit)

### 5. Run the app

**Web (Recommended):**
```bash
flutter run -d chrome
```

**Mobile browsers:** Access via network URL on mobile devices.

**Build for production:**
```bash
flutter build web --release
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

- `teams` - Organization teams (includes optional `password` field for invite code retrieval)
- `users` - User accounts with team association
- `events` - Exhibition events
- `booths` - Exhibition booths
- `photos` - Booth photos
- `flags` - Photo annotations

See `docs/COMPLETE_SETUP.sql` for the complete schema and setup instructions.

**Note**: After adding the team password feature (2026-08-03), run the migration:
```sql
-- supabase/migrations/20260803000001_add_team_password.sql
ALTER TABLE teams ADD COLUMN password TEXT;
```

## Documentation

### Setup & Configuration
- [Database Setup](docs/DATABASE_SETUP_README.md) - Supabase database configuration
- [Cloudflare Pages Deployment](docs/CLOUDFLARE_PAGES_DEPLOYMENT.md) - Production deployment guide
- [Cloudflare Proxy Setup](docs/CLOUDFLARE_PROXY_SETUP.md) - China network optimization
- [Proxy Verification Guide](docs/PROXY_VERIFICATION_GUIDE.md) - Testing proxy configuration

### Testing & QA
- [Pre-release Workflow](docs/PRE_RELEASE_WORKFLOW.md) - Release checklist
- [Manual Test Checklist](docs/manual_test_checklist.md) - Complete test scenarios
- [Smoke Test Guide](docs/smoke_test_guide.md) - Quick verification tests
- [Test Completion Report](docs/TEST_COMPLETION_REPORT_FINAL.md) - Test coverage details

### Features
- [Photo Feature Implementation](docs/PHOTO_FEATURE_IMPLEMENTATION.md) - Photo upload & annotation
- [Event Management Summary](docs/event_management_summary.md) - Event/booth workflows
- [Speed Optimization Report](docs/SPEED_OPTIMIZATION_2026_08.md) - WebP migration & performance improvements

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

## Support

For issues and questions, please open an issue on GitHub.
