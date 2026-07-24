import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/create_post/create_post_screen.dart';
import '../../screens/edit_post/edit_post_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/post/post_detail_screen.dart';

class AppRouter {
  static GoRouter build(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final loggedIn = authProvider.isLoggedIn;
        final loc = state.matchedLocation;

        final requiresAuth = loc == '/create-post' || loc.startsWith('/edit-post');

        if (!loggedIn && requiresAuth) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/post/:id',
          builder: (context, state) => PostDetailScreen(
            postId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/create-post',
          builder: (context, state) => const CreatePostScreen(),
        ),
        GoRoute(
          path: '/edit-post/:id',
          builder: (context, state) => EditPostScreen(
            postId: state.pathParameters['id']!,
          ),
        ),
      ],
    );
  }
}