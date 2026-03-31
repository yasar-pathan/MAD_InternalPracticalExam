import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    // Artificial delay for splash screen effect
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    final authState = ref.read(authStateProvider);
    
    authState.when(
      data: (user) {
        if (user != null) {
          context.go('/home');
        } else {
          context.go('/login');
        }
      },
      loading: () {}, // Handled by UI
      error: (err, stack) {
        context.go('/login');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      if (!next.isLoading) {
        next.whenData((user) {
          if (user != null) {
            context.go('/home');
          } else {
            context.go('/login');
          }
        });
      }
    });

    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag, size: 80, color: AppColors.white),
            SizedBox(height: 16),
            Text(
              'TradeHub',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: AppColors.white),
          ],
        ),
      ),
    );
  }
}
