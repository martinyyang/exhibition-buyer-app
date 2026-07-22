import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:exhibition_buyer_app/features/flag/services/flag_service.dart';
import 'package:exhibition_buyer_app/features/flag/models/flag.dart';

@GenerateMocks([SupabaseClient, PostgrestFilterBuilder, PostgrestTransformBuilder])
import 'flag_service_test.mocks.dart';

void main() {
  late MockSupabaseClient mockSupabase;
  late FlagService flagService;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    flagService = FlagService(mockSupabase);
  });

  group('FlagService - 旗子创建', () {
    test('创建第一个旗子时编号为1', () async {
      final photoId = 'photo-123';
      final userId = 'user-123';

      // Mock查询最大编号（空结果）
      final mockFilterBuilder = MockPostgrestFilterBuilder();
      final mockTransformBuilder = MockPostgrestTransformBuilder();

      when(mockSupabase.from('flags')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select('number')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('photo_id', photoId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.order('number', ascending: false)).thenReturn(mockTransformBuilder);
      when(mockTransformBuilder.limit(1)).thenAnswer((_) async => []);

      // Mock插入操作
      when(mockFilterBuilder.insert(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.single()).thenAnswer((_) async => {
            'id': 'flag-1',
            'photo_id': photoId,
            'number': 1,
            'position_x': 0.5,
            'position_y': 0.5,
            'needs_attention': false,
            'created_by': userId,
            'created_at': DateTime.now().toIso8601String(),
          });

      final flag = await flagService.createFlag(
        photoId: photoId,
        positionX: 0.5,
        positionY: 0.5,
        createdBy: userId,
      );

      expect(flag.number, 1);
      expect(flag.photoId, photoId);
      expect(flag.positionX, 0.5);
      expect(flag.positionY, 0.5);
    });

    test('创建第二个旗子时编号自动递增', () async {
      final photoId = 'photo-123';
      final userId = 'user-123';

      // Mock查询最大编号（返回1）
      final mockFilterBuilder = MockPostgrestFilterBuilder();
      final mockTransformBuilder = MockPostgrestTransformBuilder();

      when(mockSupabase.from('flags')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select('number')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('photo_id', photoId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.order('number', ascending: false)).thenReturn(mockTransformBuilder);
      when(mockTransformBuilder.limit(1)).thenAnswer((_) async => [
            {'number': 1}
          ]);

      // Mock插入操作
      when(mockFilterBuilder.insert(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.single()).thenAnswer((_) async => {
            'id': 'flag-2',
            'photo_id': photoId,
            'number': 2,
            'position_x': 0.3,
            'position_y': 0.7,
            'needs_attention': false,
            'created_by': userId,
            'created_at': DateTime.now().toIso8601String(),
          });

      final flag = await flagService.createFlag(
        photoId: photoId,
        positionX: 0.3,
        positionY: 0.7,
        createdBy: userId,
      );

      expect(flag.number, 2);
    });

    test('创建旗子时坐标值在0-1范围内', () async {
      final photoId = 'photo-123';
      final userId = 'user-123';

      final mockFilterBuilder = MockPostgrestFilterBuilder();
      final mockTransformBuilder = MockPostgrestTransformBuilder();

      when(mockSupabase.from('flags')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select('number')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('photo_id', photoId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.order('number', ascending: false)).thenReturn(mockTransformBuilder);
      when(mockTransformBuilder.limit(1)).thenAnswer((_) async => []);

      when(mockFilterBuilder.insert(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.single()).thenAnswer((_) async => {
            'id': 'flag-1',
            'photo_id': photoId,
            'number': 1,
            'position_x': 0.0,
            'position_y': 1.0,
            'needs_attention': false,
            'created_by': userId,
            'created_at': DateTime.now().toIso8601String(),
          });

      final flag = await flagService.createFlag(
        photoId: photoId,
        positionX: 0.0,
        positionY: 1.0,
        createdBy: userId,
      );

      expect(flag.positionX, greaterThanOrEqualTo(0.0));
      expect(flag.positionX, lessThanOrEqualTo(1.0));
      expect(flag.positionY, greaterThanOrEqualTo(0.0));
      expect(flag.positionY, lessThanOrEqualTo(1.0));
    });
  });

  group('FlagService - 买手更新报价', () {
    test('更新报价时自动设置buyer_price_updated_at', () async {
      final flagId = 'flag-123';
      final now = DateTime.now();

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('flags')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.update(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('id', flagId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.single()).thenAnswer((_) async => {
            'id': flagId,
            'photo_id': 'photo-123',
            'number': 1,
            'position_x': 0.5,
            'position_y': 0.5,
            'price_rmb': 1000.0,
            'buyer_price_updated_at': now.toIso8601String(),
            'needs_attention': false,
            'created_by': 'user-123',
            'created_at': now.toIso8601String(),
          });

      final flag = await flagService.updateBuyerPrice(
        flagId: flagId,
        priceRmb: 1000.0,
      );

      expect(flag.priceRmb, 1000.0);
      expect(flag.buyerPriceUpdatedAt, isNotNull);
      expect(flag.needsAttention, false);
    });

    test('更新报价时使用公式计算换算价格', () async {
      final flagId = 'flag-123';
      final now = DateTime.now();

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('flags')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.update(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('id', flagId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.single()).thenAnswer((_) async => {
            'id': flagId,
            'photo_id': 'photo-123',
            'number': 1,
            'position_x': 0.5,
            'position_y': 0.5,
            'price_rmb': 1000.0,
            'price_converted': 140.0,
            'buyer_price_updated_at': now.toIso8601String(),
            'needs_attention': false,
            'created_by': 'user-123',
            'created_at': now.toIso8601String(),
          });

      final flag = await flagService.updateBuyerPrice(
        flagId: flagId,
        priceRmb: 1000.0,
        formula: 'RMB * 0.14',
      );

      expect(flag.priceRmb, 1000.0);
      expect(flag.priceConverted, 140.0);
    });

    test('更新报价时清除警告标记', () async {
      final flagId = 'flag-123';
      final now = DateTime.now();

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('flags')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.update(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('id', flagId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.single()).thenAnswer((_) async => {
            'id': flagId,
            'photo_id': 'photo-123',
            'number': 1,
            'position_x': 0.5,
            'position_y': 0.5,
            'price_rmb': 1000.0,
            'target_price': 900.0,
            'target_price_updated_at': now.subtract(Duration(hours: 1)).toIso8601String(),
            'buyer_price_updated_at': now.toIso8601String(),
            'needs_attention': false,
            'created_by': 'user-123',
            'created_at': now.toIso8601String(),
          });

      final flag = await flagService.updateBuyerPrice(
        flagId: flagId,
        priceRmb: 1000.0,
      );

      expect(flag.needsAttention, false);
    });
  });

  group('FlagService - 远程设置目标价', () {
    test('设置目标价时自动设置target_price_updated_at', () async {
      final flagId = 'flag-123';
      final now = DateTime.now();

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('flags')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.update(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('id', flagId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.single()).thenAnswer((_) async => {
            'id': flagId,
            'photo_id': 'photo-123',
            'number': 1,
            'position_x': 0.5,
            'position_y': 0.5,
            'target_price': 900.0,
            'target_price_updated_at': now.toIso8601String(),
            'needs_attention': true,
            'created_by': 'user-123',
            'created_at': now.toIso8601String(),
          });

      final flag = await flagService.setTargetPrice(
        flagId: flagId,
        targetPrice: 900.0,
      );

      expect(flag.targetPrice, 900.0);
      expect(flag.targetPriceUpdatedAt, isNotNull);
    });

    test('设置目标价时触发警告标记', () async {
      final flagId = 'flag-123';
      final now = DateTime.now();

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('flags')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.update(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('id', flagId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.single()).thenAnswer((_) async => {
            'id': flagId,
            'photo_id': 'photo-123',
            'number': 1,
            'position_x': 0.5,
            'position_y': 0.5,
            'target_price': 900.0,
            'target_price_updated_at': now.toIso8601String(),
            'needs_attention': true,
            'created_by': 'user-123',
            'created_at': now.toIso8601String(),
          });

      final flag = await flagService.setTargetPrice(
        flagId: flagId,
        targetPrice: 900.0,
      );

      expect(flag.needsAttention, true);
    });
  });

  group('FlagService - 红色警告标记逻辑', () {
    test('远程设置目标价后needs_attention为true', () async {
      final flagId = 'flag-123';
      final now = DateTime.now();

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('flags')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.update(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('id', flagId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.single()).thenAnswer((_) async => {
            'id': flagId,
            'photo_id': 'photo-123',
            'number': 1,
            'position_x': 0.5,
            'position_y': 0.5,
            'price_rmb': 1000.0,
            'target_price': 900.0,
            'target_price_updated_at': now.toIso8601String(),
            'buyer_price_updated_at': now.subtract(Duration(hours: 1)).toIso8601String(),
            'needs_attention': true,
            'created_by': 'user-123',
            'created_at': now.toIso8601String(),
          });

      final flag = await flagService.setTargetPrice(
        flagId: flagId,
        targetPrice: 900.0,
      );

      expect(flag.needsAttention, true);
      expect(flag.targetPrice, 900.0);
      expect(flag.targetPriceUpdatedAt, isNotNull);
    });

    test('买手更新报价后needs_attention为false', () async {
      final flagId = 'flag-123';
      final now = DateTime.now();

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('flags')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.update(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('id', flagId)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.single()).thenAnswer((_) async => {
            'id': flagId,
            'photo_id': 'photo-123',
            'number': 1,
            'position_x': 0.5,
            'position_y': 0.5,
            'price_rmb': 1000.0,
            'target_price': 900.0,
            'target_price_updated_at': now.subtract(Duration(hours: 1)).toIso8601String(),
            'buyer_price_updated_at': now.toIso8601String(),
            'needs_attention': false,
            'created_by': 'user-123',
            'created_at': now.toIso8601String(),
          });

      final flag = await flagService.updateBuyerPrice(
        flagId: flagId,
        priceRmb: 1000.0,
      );

      expect(flag.needsAttention, false);
      expect(flag.buyerPriceUpdatedAt!.isAfter(flag.targetPriceUpdatedAt!), true);
    });
  });

  group('FlagService - 获取旗子', () {
    test('getFlags返回指定照片的所有旗子', () async {
      final photoId = 'photo-123';

      final mockFilterBuilder = MockPostgrestFilterBuilder();
      final mockTransformBuilder = MockPostgrestTransformBuilder();

      when(mockSupabase.from('flags')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('photo_id', photoId)).thenReturn(mockTransformBuilder);
      when(mockTransformBuilder.order('number', ascending: true)).thenAnswer((_) async => [
            {
              'id': 'flag-1',
              'photo_id': photoId,
              'number': 1,
              'position_x': 0.5,
              'position_y': 0.5,
              'needs_attention': false,
              'created_by': 'user-123',
              'created_at': DateTime.now().toIso8601String(),
            },
            {
              'id': 'flag-2',
              'photo_id': photoId,
              'number': 2,
              'position_x': 0.3,
              'position_y': 0.7,
              'needs_attention': true,
              'created_by': 'user-123',
              'created_at': DateTime.now().toIso8601String(),
            },
          ]);

      final flags = await flagService.getFlags(photoId);

      expect(flags.length, 2);
      expect(flags[0].number, 1);
      expect(flags[1].number, 2);
      expect(flags[0].photoId, photoId);
      expect(flags[1].photoId, photoId);
    });

    test('getFlags返回按编号升序排列的旗子', () async {
      final photoId = 'photo-123';

      final mockFilterBuilder = MockPostgrestFilterBuilder();
      final mockTransformBuilder = MockPostgrestTransformBuilder();

      when(mockSupabase.from('flags')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('photo_id', photoId)).thenReturn(mockTransformBuilder);
      when(mockTransformBuilder.order('number', ascending: true)).thenAnswer((_) async => [
            {
              'id': 'flag-1',
              'photo_id': photoId,
              'number': 1,
              'position_x': 0.5,
              'position_y': 0.5,
              'needs_attention': false,
              'created_by': 'user-123',
              'created_at': DateTime.now().toIso8601String(),
            },
            {
              'id': 'flag-2',
              'photo_id': photoId,
              'number': 3,
              'position_x': 0.8,
              'position_y': 0.2,
              'needs_attention': false,
              'created_by': 'user-123',
              'created_at': DateTime.now().toIso8601String(),
            },
            {
              'id': 'flag-3',
              'photo_id': photoId,
              'number': 5,
              'position_x': 0.1,
              'position_y': 0.9,
              'needs_attention': false,
              'created_by': 'user-123',
              'created_at': DateTime.now().toIso8601String(),
            },
          ]);

      final flags = await flagService.getFlags(photoId);

      expect(flags.length, 3);
      expect(flags[0].number, lessThan(flags[1].number));
      expect(flags[1].number, lessThan(flags[2].number));
    });

    test('照片没有旗子时返回空列表', () async {
      final photoId = 'photo-123';

      final mockFilterBuilder = MockPostgrestFilterBuilder();
      final mockTransformBuilder = MockPostgrestTransformBuilder();

      when(mockSupabase.from('flags')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('photo_id', photoId)).thenReturn(mockTransformBuilder);
      when(mockTransformBuilder.order('number', ascending: true)).thenAnswer((_) async => []);

      final flags = await flagService.getFlags(photoId);

      expect(flags, isEmpty);
    });
  });

  group('FlagService - 删除旗子', () {
    test('成功删除旗子', () async {
      final flagId = 'flag-123';

      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockSupabase.from('flags')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.delete()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('id', flagId)).thenAnswer((_) async => null);

      await flagService.deleteFlag(flagId);

      verify(mockFilterBuilder.delete()).called(1);
      verify(mockFilterBuilder.eq('id', flagId)).called(1);
    });
  });

  group('FlagService - 数据隔离', () {
    test('不同照片的旗子编号独立计算', () async {
      final photoId1 = 'photo-111';
      final photoId2 = 'photo-222';
      final userId = 'user-123';

      // 第一张照片已有2个旗子
      final mockFilterBuilder1 = MockPostgrestFilterBuilder();
      final mockTransformBuilder1 = MockPostgrestTransformBuilder();

      when(mockSupabase.from('flags')).thenReturn(mockFilterBuilder1);
      when(mockFilterBuilder1.select('number')).thenReturn(mockFilterBuilder1);
      when(mockFilterBuilder1.eq('photo_id', photoId1)).thenReturn(mockFilterBuilder1);
      when(mockFilterBuilder1.order('number', ascending: false)).thenReturn(mockTransformBuilder1);
      when(mockTransformBuilder1.limit(1)).thenAnswer((_) async => [
            {'number': 2}
          ]);

      when(mockFilterBuilder1.insert(any)).thenReturn(mockFilterBuilder1);
      when(mockFilterBuilder1.select()).thenReturn(mockFilterBuilder1);
      when(mockFilterBuilder1.single()).thenAnswer((_) async => {
            'id': 'flag-3',
            'photo_id': photoId1,
            'number': 3,
            'position_x': 0.5,
            'position_y': 0.5,
            'needs_attention': false,
            'created_by': userId,
            'created_at': DateTime.now().toIso8601String(),
          });

      final flag1 = await flagService.createFlag(
        photoId: photoId1,
        positionX: 0.5,
        positionY: 0.5,
        createdBy: userId,
      );

      expect(flag1.number, 3);

      // 第二张照片是第一个旗子
      final mockFilterBuilder2 = MockPostgrestFilterBuilder();
      final mockTransformBuilder2 = MockPostgrestTransformBuilder();

      when(mockSupabase.from('flags')).thenReturn(mockFilterBuilder2);
      when(mockFilterBuilder2.select('number')).thenReturn(mockFilterBuilder2);
      when(mockFilterBuilder2.eq('photo_id', photoId2)).thenReturn(mockFilterBuilder2);
      when(mockFilterBuilder2.order('number', ascending: false)).thenReturn(mockTransformBuilder2);
      when(mockTransformBuilder2.limit(1)).thenAnswer((_) async => []);

      when(mockFilterBuilder2.insert(any)).thenReturn(mockFilterBuilder2);
      when(mockFilterBuilder2.select()).thenReturn(mockFilterBuilder2);
      when(mockFilterBuilder2.single()).thenAnswer((_) async => {
            'id': 'flag-4',
            'photo_id': photoId2,
            'number': 1,
            'position_x': 0.5,
            'position_y': 0.5,
            'needs_attention': false,
            'created_by': userId,
            'created_at': DateTime.now().toIso8601String(),
          });

      final flag2 = await flagService.createFlag(
        photoId: photoId2,
        positionX: 0.5,
        positionY: 0.5,
        createdBy: userId,
      );

      expect(flag2.number, 1);
    });
  });
}
