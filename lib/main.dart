import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/comment_provider.dart';
import 'providers/post_provider.dart';
import 'utils/constants.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
Future<void> main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  // NOTE: newer supabase_flutter releases (2.6+) renamed this param to
  // `publishableKey` to match Supabase's new API key format. If your
  // installed version doesn't recognize `publishableKey`, use `anonKey:`
  // instead — same value either way.
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
      ],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _router = AppRouter.build(authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Blog / Forum App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        cardTheme: CardThemeData(
          color: const Color(0xFF2A2A2A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}