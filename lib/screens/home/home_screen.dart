import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../widgets/post_card.dart';
import '/screens/create_post/create_post_screen.dart';
import '../login/login_screen.dart';
import '../register/register_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load posts as soon as the screen mounts — works whether or not
    // the user is logged in, since post listing is public.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchInitial();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<PostProvider>().fetchMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final postProvider = context.watch<PostProvider>();

    return Scaffold(
 appBar: AppBar(
  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
  title: MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: _refreshFeed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Blog / Forum'),
      ),
    ),
  ),
actions: [
  if (auth.isLoggedIn) ...[
    Padding(
    padding: const EdgeInsets.only(right: 4),
    child: Text(
      auth.currentProfile?.displayName ??
        'User-${auth.currentUser?.id.substring(0, 8) ?? ''}'
      ),
    ),
    PopupMenuButton<String>(
  icon: const CircleAvatar(
    radius: 16,
    child: Icon(Icons.person, size: 18),
  ),
  offset: const Offset(0, 45),
  onSelected: (value) {
    if (value == 'logout') _confirmLogout(context);
  },
  itemBuilder: (context) => const [
    PopupMenuItem(value: 'logout', child: Text('Logout')),
  ],
),
  ] else ...[
    TextButton(
      onPressed: () => showDialog(
        context: context,
        builder: (_) => const LoginScreen(),
      ),
      child: const Text('Sign In'),
    ),
    TextButton(
      onPressed: () => showDialog(
        context: context,
        builder: (_) => const RegisterScreen(),
      ),
      child: const Text('Sign Up'),
    ),
  ],
],
),
  
  floatingActionButton: auth.isLoggedIn
          ? FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const CreatePostScreen(),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => context.read<PostProvider>().fetchInitial(),
        child: _buildBody(postProvider),
      ),
    );
  }

Future<void> _refreshFeed() async {
  if (_scrollController.hasClients) {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }
  await context.read<PostProvider>().fetchInitial();
}

Future<void> _confirmLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Logout'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    context.read<AuthProvider>().logout();
  }
}
  Widget _buildBody(PostProvider postProvider) {
 if (postProvider.isLoading && postProvider.posts.isEmpty) {
  return ListView.builder(
    padding: const EdgeInsets.symmetric(vertical: 8),
    itemCount: 4,
    itemBuilder: (context, index) => const _PostCardSkeleton(),
  );
}

  if (postProvider.errorMessage != null && postProvider.posts.isEmpty) {
    return Center(child: Text('Error: ${postProvider.errorMessage}'));
  }

  if (postProvider.posts.isEmpty) {
    return const Center(child: Text('No posts yet. Be the first to post!'));
  }

  return ListView.builder(
  controller: _scrollController,
  itemCount: postProvider.posts.length + (postProvider.hasMore ? 1 : 0),
  itemBuilder: (context, index) {
    if (index >= postProvider.posts.length) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final post = postProvider.posts[index];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: PostCard(
          post: post,
   onTap: () {
  debugPrint('Navigating to post ${post.id}');
  context.go('/post/${post.id}');
},
        ),
      ),
    );
  },
);
}
}

class _PostCardSkeleton extends StatefulWidget {
  const _PostCardSkeleton();

  @override
  State<_PostCardSkeleton> createState() => _PostCardSkeletonState();
}

class _PostCardSkeletonState extends State<_PostCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_controller),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(color: Colors.white12),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: 160, color: Colors.white12),
                  const SizedBox(height: 8),
                  Container(height: 12, width: double.infinity, color: Colors.white12),
                  const SizedBox(height: 6),
                  Container(height: 12, width: 200, color: Colors.white12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}