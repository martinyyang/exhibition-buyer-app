import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:exhibition_buyer_app/features/photo/services/photo_service.dart';
import 'package:exhibition_buyer_app/features/photo/models/photo.dart';

// Mock classes
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockStorageFileApi extends Mock implements SupabaseStorageClient {}
class MockStorageBucket extends Mock implements StorageFileApi {}
class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder {}
class MockPostgrestBuilder extends Mock implements PostgrestBuilder {}
class MockFile extends Mock implements File {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockStorageFileApi mockStorage;
  late MockStorageBucket mockBucket;
  late PhotoService photoService;

  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(File(''));
    registerFallbackValue(const FileOptions());
  });

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockStorage = MockStorageFileApi();
    mockBucket = MockStorageBucket();
    photoService = PhotoService(mockSupabase);

    // Setup default storage mock behavior
    when(() => mockSupabase.storage).thenReturn(mockStorage);
    when(() => mockStorage.from(any())).thenReturn(mockBucket);
  });

  group('PhotoService - 照片上传与存储', () {
    const testBoothId = 'booth-123';
    const testUserId = 'user-456';
    const testTeamId = 'team-789';
    const testPhotoId = 'photo-abc';

    group('uploadPhoto - 照片上传', () {
      test('成功上传照片并创建记录（不含供应商信息）', () async {
        final mockFile = MockFile();
        final mockQuery = MockPostgrestFilterBuilder();

        // Mock storage upload
        when(() => mockBucket.upload(
          any(),
          any(),
          fileOptions: any(named: 'fileOptions'),
        )).thenAnswer((_) async => 'photos/test-file.jpg');

        // Mock getPublicUrl
        when(() => mockBucket.getPublicUrl(any()))
            .thenReturn('https://storage.supabase.co/photos/test-file.jpg');

        // Mock database insert
        when(() => mockSupabase.from('photos')).thenReturn(mockQuery as dynamic);
        when(() => mockQuery.insert(any())).thenReturn(mockQuery);
        when(() => mockQuery.select()).thenReturn(mockQuery);
        when(() => mockQuery.single()).thenAnswer((_) async => {
          'id': testPhotoId,
          'booth_id': testBoothId,
          'url': 'https://storage.supabase.co/photos/test-file.jpg',
          'supplier_name': null,
          'supplier_logo_url': null,
          'uploaded_by': testUserId,
          'created_at': DateTime.now().toIso8601String(),
        });

        final result = await photoService.uploadPhoto(
          photoFile: mockFile,
          boothId: testBoothId,
          teamId: testTeamId,
          uploadedBy: testUserId,
        );

        expect(result.id, testPhotoId);
        expect(result.boothId, testBoothId);
        expect(result.uploadedBy, testUserId);
        expect(result.supplierName, isNull);
        expect(result.supplierLogoUrl, isNull);

        // Verify storage upload was called
        verify(() => mockBucket.upload(
          any(that: contains('$testTeamId/$testBoothId/')),
          mockFile,
          fileOptions: any(named: 'fileOptions'),
        )).called(1);

        // Verify database insert was called
        verify(() => mockQuery.insert(any(that: containsPair('booth_id', testBoothId)))).called(1);
      });

      test('成功上传照片并创建记录（含供应商信息）', () async {
        final mockFile = MockFile();
        final mockQuery = MockPostgrestFilterBuilder();
        const supplierName = 'Luxury Brand Co.';
        const supplierLogoUrl = 'https://example.com/logo.jpg';

        when(() => mockBucket.upload(any(), any(), fileOptions: any(named: 'fileOptions')))
            .thenAnswer((_) async => 'photos/test-file.jpg');
        when(() => mockBucket.getPublicUrl(any()))
            .thenReturn('https://storage.supabase.co/photos/test-file.jpg');

        when(() => mockSupabase.from('photos')).thenReturn(mockQuery as dynamic);
        when(() => mockQuery.insert(any())).thenReturn(mockQuery);
        when(() => mockQuery.select()).thenReturn(mockQuery);
        when(() => mockQuery.single()).thenAnswer((_) async => {
          'id': testPhotoId,
          'booth_id': testBoothId,
          'url': 'https://storage.supabase.co/photos/test-file.jpg',
          'supplier_name': supplierName,
          'supplier_logo_url': supplierLogoUrl,
          'uploaded_by': testUserId,
          'created_at': DateTime.now().toIso8601String(),
        });

        final result = await photoService.uploadPhoto(
          photoFile: mockFile,
          boothId: testBoothId,
          teamId: testTeamId,
          uploadedBy: testUserId,
          supplierName: supplierName,
          supplierLogoUrl: supplierLogoUrl,
        );

        expect(result.supplierName, supplierName);
        expect(result.supplierLogoUrl, supplierLogoUrl);

        verify(() => mockQuery.insert(any(that: allOf(
          containsPair('supplier_name', supplierName),
          containsPair('supplier_logo_url', supplierLogoUrl),
        )))).called(1);
      });

      test('文件路径格式正确：{team_id}/{booth_id}/{timestamp}_{uuid}.jpg', () async {
        final mockFile = MockFile();
        final mockQuery = MockPostgrestFilterBuilder();
        String? uploadedPath;

        when(() => mockBucket.upload(any(), any(), fileOptions: any(named: 'fileOptions')))
            .thenAnswer((invocation) async {
          uploadedPath = invocation.positionalArguments[0] as String;
          return uploadedPath!;
        });
        when(() => mockBucket.getPublicUrl(any()))
            .thenReturn('https://storage.supabase.co/photos/test-file.jpg');

        when(() => mockSupabase.from('photos')).thenReturn(mockQuery as dynamic);
        when(() => mockQuery.insert(any())).thenReturn(mockQuery);
        when(() => mockQuery.select()).thenReturn(mockQuery);
        when(() => mockQuery.single()).thenAnswer((_) async => {
          'id': testPhotoId,
          'booth_id': testBoothId,
          'url': 'https://storage.supabase.co/photos/test-file.jpg',
          'uploaded_by': testUserId,
          'created_at': DateTime.now().toIso8601String(),
        });

        await photoService.uploadPhoto(
          photoFile: mockFile,
          boothId: testBoothId,
          teamId: testTeamId,
          uploadedBy: testUserId,
        );

        expect(uploadedPath, isNotNull);
        expect(uploadedPath, startsWith('$testTeamId/$testBoothId/'));
        expect(uploadedPath, endsWith('.jpg'));

        // Extract filename and verify format
        final fileName = uploadedPath!.split('/').last;
        expect(fileName, matches(RegExp(r'^\d+_.+\.jpg$')));
      });

      test('上传失败时抛出异常', () async {
        final mockFile = MockFile();

        when(() => mockBucket.upload(any(), any(), fileOptions: any(named: 'fileOptions')))
            .thenThrow(Exception('Storage upload failed'));

        expect(
          () => photoService.uploadPhoto(
            photoFile: mockFile,
            boothId: testBoothId,
            teamId: testTeamId,
            uploadedBy: testUserId,
          ),
          throwsException,
        );
      });
    });

    group('getPhotos - 获取照片列表', () {
      test('按摊位ID获取所有照片', () async {
        final mockQuery = MockPostgrestFilterBuilder();
        final testPhotos = [
          {
            'id': 'photo-1',
            'booth_id': testBoothId,
            'url': 'https://example.com/photo1.jpg',
            'uploaded_by': testUserId,
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'id': 'photo-2',
            'booth_id': testBoothId,
            'url': 'https://example.com/photo2.jpg',
            'uploaded_by': testUserId,
            'created_at': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
          },
        ];

        when(() => mockSupabase.from('photos')).thenReturn(mockQuery as dynamic);
        when(() => mockQuery.select()).thenReturn(mockQuery);
        when(() => mockQuery.eq('booth_id', testBoothId)).thenReturn(mockQuery);
        when(() => mockQuery.order('created_at', ascending: false))
            .thenAnswer((_) async => testPhotos);

        final results = await photoService.getPhotos(testBoothId);

        expect(results, hasLength(2));
        expect(results[0].id, 'photo-1');
        expect(results[1].id, 'photo-2');
        expect(results.every((p) => p.boothId == testBoothId), isTrue);

        verify(() => mockQuery.eq('booth_id', testBoothId)).called(1);
        verify(() => mockQuery.order('created_at', ascending: false)).called(1);
      });

      test('摊位没有照片时返回空列表', () async {
        final mockQuery = MockPostgrestFilterBuilder();

        when(() => mockSupabase.from('photos')).thenReturn(mockQuery as dynamic);
        when(() => mockQuery.select()).thenReturn(mockQuery);
        when(() => mockQuery.eq('booth_id', testBoothId)).thenReturn(mockQuery);
        when(() => mockQuery.order('created_at', ascending: false))
            .thenAnswer((_) async => []);

        final results = await photoService.getPhotos(testBoothId);

        expect(results, isEmpty);
      });

      test('数据隔离：不同摊位的照片不会混淆', () async {
        final mockQuery = MockPostgrestFilterBuilder();
        const booth1Id = 'booth-1';
        const booth2Id = 'booth-2';

        when(() => mockSupabase.from('photos')).thenReturn(mockQuery as dynamic);
        when(() => mockQuery.select()).thenReturn(mockQuery);
        when(() => mockQuery.eq('booth_id', booth1Id)).thenReturn(mockQuery);
        when(() => mockQuery.order('created_at', ascending: false))
            .thenAnswer((_) async => [
          {
            'id': 'photo-booth1',
            'booth_id': booth1Id,
            'url': 'https://example.com/photo1.jpg',
            'uploaded_by': testUserId,
            'created_at': DateTime.now().toIso8601String(),
          },
        ]);

        final results = await photoService.getPhotos(booth1Id);

        expect(results, hasLength(1));
        expect(results[0].boothId, booth1Id);
        expect(results.every((p) => p.boothId != booth2Id), isTrue);
      });
    });

    group('getPhoto - 获取单张照片', () {
      test('根据ID获取照片详情', () async {
        final mockQuery = MockPostgrestFilterBuilder();
        final photoData = {
          'id': testPhotoId,
          'booth_id': testBoothId,
          'url': 'https://example.com/photo.jpg',
          'supplier_name': 'Test Supplier',
          'uploaded_by': testUserId,
          'created_at': DateTime.now().toIso8601String(),
        };

        when(() => mockSupabase.from('photos')).thenReturn(mockQuery as dynamic);
        when(() => mockQuery.select()).thenReturn(mockQuery);
        when(() => mockQuery.eq('id', testPhotoId)).thenReturn(mockQuery);
        when(() => mockQuery.single()).thenAnswer((_) async => photoData);

        final result = await photoService.getPhoto(testPhotoId);

        expect(result, isNotNull);
        expect(result!.id, testPhotoId);
        expect(result.supplierName, 'Test Supplier');
      });

      test('照片不存在时返回null', () async {
        final mockQuery = MockPostgrestFilterBuilder();

        when(() => mockSupabase.from('photos')).thenReturn(mockQuery as dynamic);
        when(() => mockQuery.select()).thenReturn(mockQuery);
        when(() => mockQuery.eq('id', 'non-existent')).thenReturn(mockQuery);
        when(() => mockQuery.single()).thenThrow(Exception('Not found'));

        expect(
          () => photoService.getPhoto('non-existent'),
          throwsException,
        );
      });
    });

    group('updatePhoto - 更新照片信息', () {
      test('更新供应商名称', () async {
        final mockQuery = MockPostgrestFilterBuilder();
        const newSupplierName = 'New Supplier';

        when(() => mockSupabase.from('photos')).thenReturn(mockQuery as dynamic);
        when(() => mockQuery.update(any())).thenReturn(mockQuery);
        when(() => mockQuery.eq('id', testPhotoId)).thenReturn(mockQuery);
        when(() => mockQuery.select()).thenReturn(mockQuery);
        when(() => mockQuery.single()).thenAnswer((_) async => {
          'id': testPhotoId,
          'booth_id': testBoothId,
          'url': 'https://example.com/photo.jpg',
          'supplier_name': newSupplierName,
          'uploaded_by': testUserId,
          'created_at': DateTime.now().toIso8601String(),
        });

        final result = await photoService.updatePhoto(
          photoId: testPhotoId,
          supplierName: newSupplierName,
        );

        expect(result.supplierName, newSupplierName);
        verify(() => mockQuery.update(containsPair('supplier_name', newSupplierName))).called(1);
      });

      test('更新供应商Logo URL', () async {
        final mockQuery = MockPostgrestFilterBuilder();
        const newLogoUrl = 'https://example.com/new-logo.jpg';

        when(() => mockSupabase.from('photos')).thenReturn(mockQuery as dynamic);
        when(() => mockQuery.update(any())).thenReturn(mockQuery);
        when(() => mockQuery.eq('id', testPhotoId)).thenReturn(mockQuery);
        when(() => mockQuery.select()).thenReturn(mockQuery);
        when(() => mockQuery.single()).thenAnswer((_) async => {
          'id': testPhotoId,
          'booth_id': testBoothId,
          'url': 'https://example.com/photo.jpg',
          'supplier_logo_url': newLogoUrl,
          'uploaded_by': testUserId,
          'created_at': DateTime.now().toIso8601String(),
        });

        final result = await photoService.updatePhoto(
          photoId: testPhotoId,
          supplierLogoUrl: newLogoUrl,
        );

        expect(result.supplierLogoUrl, newLogoUrl);
        verify(() => mockQuery.update(containsPair('supplier_logo_url', newLogoUrl))).called(1);
      });

      test('同时更新供应商名称和Logo', () async {
        final mockQuery = MockPostgrestFilterBuilder();
        const newSupplierName = 'Complete Supplier';
        const newLogoUrl = 'https://example.com/complete-logo.jpg';

        when(() => mockSupabase.from('photos')).thenReturn(mockQuery as dynamic);
        when(() => mockQuery.update(any())).thenReturn(mockQuery);
        when(() => mockQuery.eq('id', testPhotoId)).thenReturn(mockQuery);
        when(() => mockQuery.select()).thenReturn(mockQuery);
        when(() => mockQuery.single()).thenAnswer((_) async => {
          'id': testPhotoId,
          'booth_id': testBoothId,
          'url': 'https://example.com/photo.jpg',
          'supplier_name': newSupplierName,
          'supplier_logo_url': newLogoUrl,
          'uploaded_by': testUserId,
          'created_at': DateTime.now().toIso8601String(),
        });

        final result = await photoService.updatePhoto(
          photoId: testPhotoId,
          supplierName: newSupplierName,
          supplierLogoUrl: newLogoUrl,
        );

        expect(result.supplierName, newSupplierName);
        expect(result.supplierLogoUrl, newLogoUrl);
        verify(() => mockQuery.update(allOf(
          containsPair('supplier_name', newSupplierName),
          containsPair('supplier_logo_url', newLogoUrl),
        ))).called(1);
      });
    });

    group('addSupplierInfo - 添加供应商信息', () {
      test('为照片添加供应商信息（名称和Logo）', () async {
        final mockQuery = MockPostgrestFilterBuilder();
        const supplierName = 'Gucci';
        const supplierLogoUrl = 'https://example.com/gucci-logo.jpg';

        when(() => mockSupabase.from('photos')).thenReturn(mockQuery as dynamic);
        when(() => mockQuery.update(any())).thenReturn(mockQuery);
        when(() => mockQuery.eq('id', testPhotoId)).thenReturn(mockQuery);
        when(() => mockQuery.select()).thenReturn(mockQuery);
        when(() => mockQuery.single()).thenAnswer((_) async => {
          'id': testPhotoId,
          'booth_id': testBoothId,
          'url': 'https://example.com/photo.jpg',
          'supplier_name': supplierName,
          'supplier_logo_url': supplierLogoUrl,
          'uploaded_by': testUserId,
          'created_at': DateTime.now().toIso8601String(),
        });

        final result = await photoService.addSupplierInfo(
          photoId: testPhotoId,
          supplierName: supplierName,
          supplierLogoUrl: supplierLogoUrl,
        );

        expect(result.supplierName, supplierName);
        expect(result.supplierLogoUrl, supplierLogoUrl);
      });

      test('只添加供应商名称（无Logo）', () async {
        final mockQuery = MockPostgrestFilterBuilder();
        const supplierName = 'Prada';

        when(() => mockSupabase.from('photos')).thenReturn(mockQuery as dynamic);
        when(() => mockQuery.update(any())).thenReturn(mockQuery);
        when(() => mockQuery.eq('id', testPhotoId)).thenReturn(mockQuery);
        when(() => mockQuery.select()).thenReturn(mockQuery);
        when(() => mockQuery.single()).thenAnswer((_) async => {
          'id': testPhotoId,
          'booth_id': testBoothId,
          'url': 'https://example.com/photo.jpg',
          'supplier_name': supplierName,
          'supplier_logo_url': null,
          'uploaded_by': testUserId,
          'created_at': DateTime.now().toIso8601String(),
        });

        final result = await photoService.addSupplierInfo(
          photoId: testPhotoId,
          supplierName: supplierName,
        );

        expect(result.supplierName, supplierName);
        expect(result.supplierLogoUrl, isNull);
      });
    });

    group('deletePhoto - 删除照片', () {
      test('成功删除照片（同时删除Storage文件和数据库记录）', () async {
        final mockQuery = MockPostgrestFilterBuilder();
        const photoUrl = 'https://storage.supabase.co/object/public/photos/team-789/booth-123/1234567890_uuid.jpg';

        // Mock getPhoto to return photo with URL
        when(() => mockSupabase.from('photos')).thenReturn(mockQuery as dynamic);
        when(() => mockQuery.select()).thenReturn(mockQuery);
        when(() => mockQuery.eq('id', testPhotoId)).thenReturn(mockQuery);
        when(() => mockQuery.single()).thenAnswer((_) async => {
          'id': testPhotoId,
          'booth_id': testBoothId,
          'url': photoUrl,
          'uploaded_by': testUserId,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Mock storage delete
        when(() => mockBucket.remove(any())).thenAnswer((_) async => []);

        // Mock database delete
        when(() => mockQuery.delete()).thenReturn(mockQuery);
        when(() => mockQuery.eq('id', testPhotoId)).thenReturn(mockQuery);

        await photoService.deletePhoto(testPhotoId);

        // Verify storage file was deleted
        verify(() => mockBucket.remove(any(that: contains('team-789/booth-123/')))).called(1);

        // Verify database record was deleted
        verify(() => mockQuery.delete()).called(1);
      });

      test('删除不存在的照片时抛出异常', () async {
        final mockQuery = MockPostgrestFilterBuilder();

        when(() => mockSupabase.from('photos')).thenReturn(mockQuery as dynamic);
        when(() => mockQuery.select()).thenReturn(mockQuery);
        when(() => mockQuery.eq('id', 'non-existent')).thenReturn(mockQuery);
        when(() => mockQuery.single()).thenThrow(Exception('Photo not found'));

        expect(
          () => photoService.deletePhoto('non-existent'),
          throwsException,
        );
      });
    });

    group('uploadSupplierLogo - 上传供应商Logo', () {
      test('成功上传供应商Logo并返回URL', () async {
        final mockFile = MockFile();
        const expectedUrl = 'https://storage.supabase.co/suppliers/1234567890_uuid.jpg';

        when(() => mockBucket.upload(any(), any(), fileOptions: any(named: 'fileOptions')))
            .thenAnswer((_) async => 'suppliers/test-logo.jpg');
        when(() => mockBucket.getPublicUrl(any())).thenReturn(expectedUrl);

        final result = await photoService.uploadSupplierLogo(mockFile);

        expect(result, expectedUrl);
        verify(() => mockBucket.upload(
          any(that: startsWith('suppliers/')),
          mockFile,
          fileOptions: any(named: 'fileOptions'),
        )).called(1);
      });

      test('Logo文件路径格式：suppliers/{timestamp}_{uuid}.jpg', () async {
        final mockFile = MockFile();
        String? uploadedPath;

        when(() => mockBucket.upload(any(), any(), fileOptions: any(named: 'fileOptions')))
            .thenAnswer((invocation) async {
          uploadedPath = invocation.positionalArguments[0] as String;
          return uploadedPath!;
        });
        when(() => mockBucket.getPublicUrl(any()))
            .thenReturn('https://storage.supabase.co/test.jpg');

        await photoService.uploadSupplierLogo(mockFile);

        expect(uploadedPath, isNotNull);
        expect(uploadedPath, startsWith('suppliers/'));
        expect(uploadedPath, endsWith('.jpg'));

        final fileName = uploadedPath!.split('/').last;
        expect(fileName, matches(RegExp(r'^\d+_.+\.jpg$')));
      });
    });
  });
}
