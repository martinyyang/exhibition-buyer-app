import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exhibition_buyer_app/core/services/supabase_client.dart';
import 'package:exhibition_buyer_app/features/flag/services/flag_service.dart';
import 'package:exhibition_buyer_app/features/photo/services/photo_service.dart';
import 'package:exhibition_buyer_app/features/booth/services/booth_service.dart';
import 'package:exhibition_buyer_app/features/event/services/event_service.dart';
import 'package:exhibition_buyer_app/core/services/realtime_service.dart';
import 'package:exhibition_buyer_app/features/booth/models/booth.dart';
import 'package:exhibition_buyer_app/features/photo/models/photo.dart';
import 'package:exhibition_buyer_app/features/flag/models/flag.dart';
import 'package:exhibition_buyer_app/features/event/models/event.dart';
import 'package:exhibition_buyer_app/features/booth/providers/booth_provider.dart';

// Mock classes for widget tests
class MockSupabaseService extends Mock implements SupabaseService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockSession extends Mock implements Session {}

class MockFlagService extends Mock implements FlagService {}

class MockPhotoService extends Mock implements PhotoService {}

class MockBoothService extends Mock implements BoothService {}

class MockEventService extends Mock implements EventService {}

class MockRealtimeService extends Mock implements RealtimeService {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

// Fake classes for fallback values
class FakePostgresChangeFilter extends Fake implements PostgresChangeFilter {}

class FakeRealtimeChannel extends Fake implements RealtimeChannel {}

// Mock StateNotifier for BoothsProvider
class MockBoothsNotifier extends BoothsNotifier {
  MockBoothsNotifier(List<Booth> booths, MockBoothService boothService, MockRealtimeService realtimeService)
      : super(boothService, realtimeService, 'test-event-id', 'test-team-id') {
    state = AsyncValue.data(booths);
  }
}
