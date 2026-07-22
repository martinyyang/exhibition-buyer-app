import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ppwjblvnixqeympfcqgs.supabase.co',
    anonKey: 'sb_publishable_4MYm7DWBzUiT5E4YCRWaZg_9W95UCHg',
  );

  runApp(
    const ProviderScope(
      child: ExhibitionBuyerApp(),
    ),
  );
}

class ExhibitionBuyerApp extends ConsumerWidget {
  const ExhibitionBuyerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '展会采购协作',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
