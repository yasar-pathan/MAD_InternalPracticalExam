import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/listing/create_listing_screen.dart';
import '../../screens/listing/edit_listing_screen.dart';
import '../../screens/listing/listing_detail_screen.dart';
import '../../screens/chat/chat_list_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/orders/orders_screen.dart';
import '../../screens/profile/profile_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/chats',
          builder: (context, state) => const ChatListScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(), // Current user profile
        ),
      ],
    ),

    GoRoute(
      path: '/listing/:id', 
      builder: (context, state) => ListingDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(path: '/create-listing', builder: (context, state) => const CreateListingScreen()),
    GoRoute(
      path: '/edit-listing/:id',
      builder: (context, state) => EditListingScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
    GoRoute(
      path: '/chat/:chatId', 
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>? ?? {};
        return ChatScreen(
          chatId: state.pathParameters['chatId']!,
          otherUserId: extras['otherUserId'] ?? '',
          otherUserName: extras['otherUserName'] ?? 'User',
        );
      },
    ),
    GoRoute(
      path: '/profile/:uid', 
      builder: (context, state) => ProfileScreen(uid: state.pathParameters['uid']), // Target user profile
    ),
  ],
);

class ScaffoldWithNavBar extends ConsumerWidget {
  final Widget child;
  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFE65100),
        unselectedItemColor: Colors.grey,
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: _ChatBadge(), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/chats')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/chats');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}

class _ChatBadge extends ConsumerWidget {
  const _ChatBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).value?.uid;
    if (uid == null) {
      return const Icon(Icons.chat);
    }

    final unreadAsync = ref.watch(unreadChatCountProvider(uid));
    final unread = unreadAsync.value ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.chat),
        if (unread > 0)
          Positioned(
            right: -8,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
