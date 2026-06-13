import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:review_app/views/auth/onboarding_screen.dart'; // Import the actual OnboardingScreen

import 'package:review_app/views/auth/login_screen.dart';
import 'package:review_app/views/auth/splash_screen.dart';
import 'package:review_app/views/auth/register_screen.dart';
import 'package:review_app/views/auth/forgot_password_screen.dart';
import 'package:review_app/views/client/home_screen.dart';
import 'package:review_app/views/client/search_screen.dart';
import 'package:review_app/views/client/favorites_screen.dart';
import 'package:review_app/views/client/profile_screen.dart';
import 'package:review_app/views/client/business_detail_screen.dart';
import 'package:review_app/views/business/business_create_screen.dart';
import 'package:review_app/views/business/business_dashboard_screen.dart';
import 'package:review_app/views/business/business_edit_screen.dart';
import 'package:review_app/views/business/business_statistics_screen.dart';
import 'package:review_app/views/business/review_management_screen.dart';
import 'package:review_app/views/admin/admin_dashboard_screen.dart';
import 'package:review_app/views/admin/user_management_screen.dart';
import 'package:review_app/views/admin/business_approval_screen.dart';
import 'package:review_app/views/admin/reports_management_screen.dart';
import 'package:review_app/views/admin/category_management_screen.dart';
import 'package:review_app/views/client/review_screen.dart';
import 'package:review_app/widgets/app_drawer.dart';
import 'package:review_app/widgets/custom_bottom_nav.dart';

// ================= AUTH STATE =================

class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.userRole = 'guest',
    this.userId = '',
  });

  final bool isAuthenticated;
  final String userRole;
  final String userId;

  AuthState copyWith({
    bool? isAuthenticated,
    String? userRole,
    String? userId,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userRole: userRole ?? this.userRole,
      userId: userId ?? this.userId,
    );
  }
}

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>(
  (ref) => AuthStateNotifier(),
);

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(const AuthState());

  void loginAsClient(String id) => state = state.copyWith(
    isAuthenticated: true,
    userRole: 'client',
    userId: id,
  );

  void loginAsBusiness(String id) => state = state.copyWith(
    isAuthenticated: true,
    userRole: 'business',
    userId: id,
  );

  void loginAsAdmin(String id) => state = state.copyWith(
    isAuthenticated: true,
    userRole: 'admin',
    userId: id,
  );

  void logout() => state = const AuthState();
}

// ================= SHELL CLIENT =================

class ClientShell extends ConsumerStatefulWidget {
  final Widget child;
  const ClientShell({super.key, required this.child});

  @override
  ConsumerState<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends ConsumerState<ClientShell> {
  int _selectedIndex = 0;
  DateTime? _lastQuitPress;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final navigator = Navigator.maybeOf(context);
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
          return;
        }

        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          context.go('/home');
          return;
        }

        final now = DateTime.now();
        if (_lastQuitPress == null ||
            now.difference(_lastQuitPress!) > const Duration(seconds: 2)) {
          _lastQuitPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appuyez à nouveau pour quitter'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: CustomBottomNav(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);

            switch (index) {
              case 0:
                context.go('/home');
                break;
              case 1:
                context.go('/search');
                break;
              case 2:
                context.go('/favorites');
                break;
              case 3:
                context.go('/notifications');
                break;
              case 4:
                context.go('/profile');
                break;
            }
          },
          items: const [
            CustomBottomNavItem(icon: Icons.home, label: 'Accueil'),
            CustomBottomNavItem(icon: Icons.search, label: 'Chercher'),
            CustomBottomNavItem(icon: Icons.favorite, label: 'Favoris'),
            CustomBottomNavItem(
              icon: Icons.notifications,
              label: 'Notifications',
            ),
            CustomBottomNavItem(icon: Icons.person, label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

// ================= BUSINESS + ADMIN SHELL =================

class BusinessShell extends StatefulWidget {
  final Widget child;
  const BusinessShell({super.key, required this.child});

  @override
  State<BusinessShell> createState() => _BusinessShellState();
}

class _BusinessShellState extends State<BusinessShell> {
  DateTime? _lastQuitPress;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final navigator = Navigator.maybeOf(context);
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
          return;
        }

        final now = DateTime.now();
        if (_lastQuitPress == null ||
            now.difference(_lastQuitPress!) > const Duration(seconds: 2)) {
          _lastQuitPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appuyez à nouveau pour quitter'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        drawer: const AppDrawer(
          userRole: 'business',
          userName: 'Business',
          userEmail: 'business@email.com',
        ),
        body: widget.child,
      ),
    );
  }
}

class AdminShell extends StatefulWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  DateTime? _lastQuitPress;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final navigator = Navigator.maybeOf(context);
        if (navigator != null && navigator.canPop()) {
          navigator.pop();
          return;
        }

        final now = DateTime.now();
        if (_lastQuitPress == null ||
            now.difference(_lastQuitPress!) > const Duration(seconds: 2)) {
          _lastQuitPress = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appuyez à nouveau pour quitter'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        drawer: const AppDrawer(
          userRole: 'admin',
          userName: 'Admin',
          userEmail: 'admin@email.com',
        ),
        body: widget.child,
      ),
    );
  }
}

// ================= ROUTER =================

final goRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.uri.path;

      final public = [
        '/splash',
        '/login',
        '/register',
        '/forgot-password',
        '/onboarding',
      ];

      if (!auth.isAuthenticated && !public.contains(location)) {
        return '/login';
      }

      if (auth.isAuthenticated && public.contains(location)) {
        switch (auth.userRole) {
          case 'client':
            return '/home';
          case 'business':
            return '/business/dashboard';
          case 'admin':
            return '/admin/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) => ClientShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
          GoRoute(
            path: '/favorites',
            builder: (_, __) => const FavoritesScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text("Notifications"))),
          ),
          GoRoute(
            path: '/home/business/:id',
            builder: (context, state) {
              final businessId = state.pathParameters['id']!;
              return BusinessDetailScreen(businessId: businessId);
            },
          ),
          GoRoute(
            path: '/home/reviews/:businessId',
            builder: (context, state) {
              final businessId = state.pathParameters['businessId']!;
              return ReviewScreen(businessId: businessId);
            },
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      ShellRoute(
        builder: (context, state, child) => BusinessShell(child: child),
        routes: [
          GoRoute(
            path: '/business/dashboard',
            builder: (_, __) => const BusinessDashboardScreen(),
          ),
          GoRoute(
            path: '/business/create',
            builder: (_, __) => const BusinessCreateScreen(),
          ),
          GoRoute(
            path: '/business/edit',
            builder: (_, __) => const BusinessEditScreen(),
          ),
          GoRoute(
            path: '/business/statistics',
            builder: (_, __) => const BusinessStatisticsScreen(),
          ),
          GoRoute(
            path: '/business/reviews',
            builder: (_, __) => const ReviewManagementScreen(),
          ),
        ],
      ),

      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (_, __) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (_, __) => const UserManagementScreen(),
          ),
          GoRoute(
            path: '/admin/approvals',
            builder: (_, __) => const BusinessApprovalScreen(),
          ),
          GoRoute(
            path: '/admin/reports',
            builder: (_, __) => const ReportsManagementScreen(),
          ),
          GoRoute(
            path: '/admin/categories',
            builder: (_, __) => const CategoryManagementScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text(state.error.toString()))),
  );
});
