import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:exhibition_buyer_app/features/auth/screens/login_screen.dart';
import 'package:exhibition_buyer_app/features/event/screens/event_selection_screen.dart';
import 'package:exhibition_buyer_app/features/booth/screens/booth_list_screen.dart';
import 'package:exhibition_buyer_app/features/photo/screens/photo_grid_screen.dart';
import 'package:exhibition_buyer_app/features/photo/screens/photo_detail_screen.dart';
import 'package:exhibition_buyer_app/features/auth/providers/auth_provider.dart';

// 路由Provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';

      // 未登录且不在登录页 -> 跳转到登录页
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // 已登录且在登录页 -> 跳转到场次选择页
      if (isLoggedIn && isLoggingIn) {
        return '/events';
      }

      return null;
    },
    routes: [
      // 登录页
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // 场次选择页
      GoRoute(
        path: '/events',
        name: 'events',
        builder: (context, state) => const EventSelectionScreen(),
      ),

      // 摊位列表页
      GoRoute(
        path: '/events/:eventId/booths',
        name: 'booths',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return BoothListScreen(eventId: eventId);
        },
      ),

      // 照片网格页
      GoRoute(
        path: '/booths/:boothId/photos',
        name: 'photos',
        builder: (context, state) {
          final boothId = state.pathParameters['boothId']!;
          return PhotoGridScreen(boothId: boothId);
        },
      ),

      // 照片详情页
      GoRoute(
        path: '/photos/:photoId',
        name: 'photo-detail',
        builder: (context, state) {
          final photoId = state.pathParameters['photoId']!;
          return PhotoDetailScreen(photoId: photoId);
        },
      ),
    ],

    // 错误页面
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '页面未找到',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? '未知错误',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/events'),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    ),
  );
});
