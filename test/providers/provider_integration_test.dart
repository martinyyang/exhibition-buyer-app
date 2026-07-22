import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exhibition_buyer_app/features/auth/providers/auth_provider.dart';
import 'package:exhibition_buyer_app/features/event/providers/event_provider.dart';
import 'package:exhibition_buyer_app/features/booth/providers/booth_provider.dart';
import 'package:exhibition_buyer_app/features/photo/providers/photo_provider.dart';
import 'package:exhibition_buyer_app/features/flag/providers/flag_provider.dart';

void main() {
  group('Provider集成测试', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('authServiceProvider 可以被正确创建', () {
      final authService = container.read(authServiceProvider);
      expect(authService, isNotNull);
    });

    test('eventServiceProvider 可以被正确创建', () {
      final eventService = container.read(eventServiceProvider);
      expect(eventService, isNotNull);
    });

    test('boothServiceProvider 可以被正确创建', () {
      final boothService = container.read(boothServiceProvider);
      expect(boothService, isNotNull);
    });

    test('photoServiceProvider 可以被正确创建', () {
      final photoService = container.read(photoServiceProvider);
      expect(photoService, isNotNull);
    });

    test('flagServiceProvider 可以被正确创建', () {
      final flagService = container.read(flagServiceProvider);
      expect(flagService, isNotNull);
    });

    test('currentUserProvider 初始状态为loading', () {
      final currentUser = container.read(currentUserProvider);
      expect(currentUser, isA<AsyncLoading>());
    });

    test('eventsProvider 初始状态为loading', () {
      final events = container.read(eventsProvider);
      expect(events, isA<AsyncLoading>());
    });

    test('boothsProvider 需要eventId参数', () {
      final booths = container.read(boothsProvider('event-123'));
      expect(booths, isA<AsyncLoading>());
    });

    test('photosProvider 需要boothId参数', () {
      final photos = container.read(photosProvider('booth-123'));
      expect(photos, isA<AsyncLoading>());
    });

    test('flagsProvider 需要photoId参数', () {
      final flags = container.read(flagsProvider('photo-123'));
      expect(flags, isA<AsyncLoading>());
    });

    test('多个container可以独立工作', () {
      final container1 = ProviderContainer();
      final container2 = ProviderContainer();

      final auth1 = container1.read(authServiceProvider);
      final auth2 = container2.read(authServiceProvider);

      expect(auth1, isNotNull);
      expect(auth2, isNotNull);
      expect(identical(auth1, auth2), isFalse);

      container1.dispose();
      container2.dispose();
    });

    test('Provider依赖关系正确', () {
      // eventServiceProvider 依赖 supabaseServiceProvider
      expect(
        () => container.read(eventServiceProvider),
        returnsNormally,
      );

      // boothServiceProvider 依赖 supabaseServiceProvider
      expect(
        () => container.read(boothServiceProvider),
        returnsNormally,
      );
    });
  });
}
