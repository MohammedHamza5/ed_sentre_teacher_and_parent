import 'package:flutter/foundation.dart';
import 'package:ed_sentre_techer_and_parent/features/auth/provider/auth_provider.dart';
import 'package:ed_sentre_techer_and_parent/features/teacher/assignments/teacher_assignments_screen.dart';
import 'package:ed_sentre_techer_and_parent/features/teacher/materials/teacher_materials_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'shared/widgets/app_drawer.dart';

import 'core/utils/app_logger.dart';
import 'shared/models/enums.dart';
import 'core/widgets/genius/genius_bottom_nav.dart'; // Glassmorphism nav

// Screens
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'shared/widgets/log_viewer_screen.dart';

// Teacher Screens
import 'features/teacher/dashboard/teacher_home_screen.dart';
import 'features/teacher/schedule/teacher_schedule_screen.dart';
import 'features/teacher/attendance/teacher_attendance_screen.dart';
import 'features/teacher/students/teacher_students_screen.dart';
import 'features/teacher/curriculum/curriculum_management_screen.dart';
import 'features/teacher/curriculum/subject_detail_management_screen.dart';
import 'features/teacher/screens/groups/teacher_groups_screen.dart';
import 'features/teacher/groups/teacher_group_details_screen.dart';

import 'features/teacher/messages/teacher_messages_screen.dart';
import 'features/teacher/profile/teacher_profile_screen.dart';
import 'features/teacher/reports/teacher_reports_screen.dart';
import 'features/notifications/presentation/screens/teacher_notifications_screen.dart';
import 'features/teacher/payments/teacher_payments_screen.dart';
import 'features/ai/screens/ai_assistant_screen.dart';

// Parent Screens
import 'features/parent/dashboard/parent_home_screen.dart';
import 'features/parent/attendance/parent_attendance_screen.dart';
import 'features/parent/grades/parent_grades_screen.dart';
import 'features/parent/payments/parent_payments_screen.dart';
import 'features/parent/messages/parent_messages_screen.dart';
import 'features/parent/notifications/parent_notifications_screen.dart';
import 'features/parent/profile/parent_profile_screen.dart';
import 'features/parent/schedule/parent_schedule_screen.dart';

/// App Router Configuration using GoRouter
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: kDebugMode,

    // Redirect logic based on auth state
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      final isLoading = authProvider.isLoading;
      final isAuthenticated = authProvider.isAuthenticated;
      final userRole = authProvider.userRole;

      final isOnSplash = state.matchedLocation == '/splash';
      final isOnLogin = state.matchedLocation == '/login';
      final isOnTeacherRoute = state.matchedLocation.startsWith('/teacher');
      final isOnParentRoute = state.matchedLocation.startsWith('/parent');

      log.ui(
        'Router Redirect Check',
        data: {
          'location': state.matchedLocation,
          'isAuthenticated': isAuthenticated,
          'userRole': userRole?.name,
          'isLoading': isLoading,
        },
      );

      // Still loading, stay on splash
      if (isLoading && isOnSplash) {
        return null;
      }

      // Not authenticated, go to login
      if (!isAuthenticated && !isOnLogin && !isOnSplash) {
        return '/login';
      }

      // Authenticated, redirect based on role
      if (isAuthenticated && (isOnLogin || isOnSplash)) {
        if (userRole == UserRole.teacher) {
          return '/teacher';
        } else if (userRole == UserRole.parent) {
          return '/parent';
        }
      }

      // Role-based route protection
      if (isAuthenticated && userRole != null) {
        if (userRole == UserRole.teacher && isOnParentRoute) {
          return '/teacher';
        }
        if (userRole == UserRole.parent && isOnTeacherRoute) {
          return '/parent';
        }
      }

      return null;
    },

    // Routes
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Log Viewer
      GoRoute(
        path: '/logs',
        name: 'logs',
        builder: (context, state) => const LogViewerScreen(),
      ),

      // Login Screen
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Teacher Routes
      ShellRoute(
        builder: (context, state, child) {
          return TeacherShellScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/teacher',
            name: 'teacher-home',
            builder: (context, state) => const TeacherHomeScreen(),
            routes: [
              GoRoute(
                path: 'groups',
                name: 'teacher-groups',
                builder: (context, state) => const TeacherGroupsScreen(),
                routes: [
                  GoRoute(
                    path: ':groupId',
                    name: 'teacher-group-details',
                    builder: (context, state) {
                      final groupId = state.pathParameters['groupId']!;
                      return TeacherGroupDetailsScreen(groupId: groupId);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'schedule',
                name: 'teacher-schedule',
                builder: (context, state) => const TeacherScheduleScreen(),
              ),
              GoRoute(
                path: 'attendance',
                name: 'teacher-attendance',
                builder: (context, state) => const TeacherAttendanceScreen(),
              ),
              GoRoute(
                path: 'attendance/:groupId',
                name: 'teacher-attendance-group',
                builder: (context, state) {
                  final groupId = state.pathParameters['groupId']!;
                  return TeacherAttendanceScreen(groupId: groupId);
                },
              ),
              GoRoute(
                path: 'students',
                name: 'teacher-students',
                builder: (context, state) => const TeacherStudentsScreen(),
              ),
              GoRoute(
                path: 'curriculum',
                name: 'teacher-curriculum',
                builder: (context, state) => const CurriculumManagementScreen(),
                routes: [
                  GoRoute(
                    path: ':subjectId',
                    name: 'teacher-subject-details',
                    builder: (context, state) {
                      final subjectId = state.pathParameters['subjectId']!;
                      final extra = state.extra as Map<String, dynamic>?;
                      return SubjectDetailManagementScreen(
                        subjectId: subjectId,
                        subjectData: extra,
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'assignments',
                name: 'teacher-assignments',
                builder: (context, state) => const TeacherAssignmentsScreen(),
              ),
              GoRoute(
                path: 'materials',
                name: 'teacher-materials',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const TeacherMaterialsScreen(),
              ),
              GoRoute(
                path: 'reports',
                name: 'teacher-reports',
                builder: (context, state) => const TeacherReportsScreen(),
              ),
              GoRoute(
                path: 'payments',
                name: 'teacher-payments',
                builder: (context, state) => const TeacherPaymentsScreen(),
              ),
              GoRoute(
                path: 'ai-assistant',
                name: 'teacher-ai-assistant',
                builder: (context, state) => const AIAssistantScreen(),
              ),
              GoRoute(
                path: 'messages',
                name: 'teacher-messages',
                builder: (context, state) => const TeacherMessagesScreen(),
              ),
              GoRoute(
                path: 'notifications',
                name: 'teacher-notifications',
                builder: (context, state) => const TeacherNotificationsScreen(),
              ),
              GoRoute(
                path: 'profile',
                name: 'teacher-profile',
                builder: (context, state) => const TeacherProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Parent Routes
      ShellRoute(
        builder: (context, state, child) {
          return ParentShellScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/parent',
            name: 'parent-home',
            builder: (context, state) => const ParentHomeScreen(),
            routes: [
              GoRoute(
                path: 'attendance',
                name: 'parent-attendance',
                builder: (context, state) => const ParentAttendanceScreen(),
              ),
              GoRoute(
                path: 'grades',
                name: 'parent-grades',
                builder: (context, state) => const ParentGradesScreen(),
              ),
              GoRoute(
                path: 'payments',
                name: 'parent-payments',
                builder: (context, state) => const ParentPaymentsScreen(),
              ),
              GoRoute(
                path: 'messages',
                name: 'parent-messages',
                builder: (context, state) => const ParentMessagesScreen(),
              ),
              GoRoute(
                path: 'notifications',
                name: 'parent-notifications',
                builder: (context, state) => const ParentNotificationsScreen(),
              ),
              GoRoute(
                path: 'schedule',
                name: 'parent-schedule',
                builder: (context, state) => const ParentScheduleScreen(),
              ),
              GoRoute(
                path: 'profile',
                name: 'parent-profile',
                builder: (context, state) => const ParentProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'صفحة غير موجودة',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.message ?? 'حدث خطأ',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('العودة للرئيسية'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Teacher Shell Screen with Premium Bottom Navigation
class TeacherShellScreen extends StatefulWidget {
  final Widget child;

  const TeacherShellScreen({super.key, required this.child});

  @override
  State<TeacherShellScreen> createState() => _TeacherShellScreenState();
}

class _TeacherShellScreenState extends State<TeacherShellScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;



  // Navigation items
  static const List<_TeacherNavItem> _navItems = [
    _TeacherNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'الرئيسية',
      route: '/teacher',
    ),
    _TeacherNavItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      label: 'الجدول',
      route: '/teacher/schedule',
    ),
    _TeacherNavItem(
      icon: Icons.fact_check_outlined,
      activeIcon: Icons.fact_check_rounded,
      label: 'الحضور',
      route: '/teacher/attendance',
    ),
    _TeacherNavItem(
      icon: Icons.message_outlined,
      activeIcon: Icons.message_rounded,
      label: 'الرسائل',
      route: '/teacher/messages',
    ),
    _TeacherNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'حسابي',
      route: '/teacher/profile',
    ),
  ];

  // Routes where bottom nav bar should be visible
  static const _mainRoutes = [
    '/teacher',
    '/teacher/groups',
    '/teacher/schedule',
    '/teacher/attendance',
    '/teacher/messages',
    '/teacher/profile',
  ];

  bool _shouldShowBottomNav(String location) {
    return _mainRoutes.contains(location) ||
        location.startsWith('/teacher/attendance/');
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final showDrawer = location == '/teacher';
    final showBottomNav = _shouldShowBottomNav(location);

    return Scaffold(
      key: teacherScaffoldKey,
      drawer: showDrawer ? const TeacherAppDrawer() : null,
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: showBottomNav
          ? GeniusBottomNav(
              items: _navItems
                  .map((item) => NavItem(icon: item.icon, label: item.label))
                  .toList(),
              currentIndex: _calculateSelectedIndex(context),
              onItemSelected: (index) => _onItemTapped(index, context),
            )
          : null,
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/teacher/schedule')) return 1;
    if (location.startsWith('/teacher/attendance')) return 2;
    if (location.startsWith('/teacher/messages')) return 3;
    if (location.startsWith('/teacher/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    context.go(_navItems[index].route);
  }
}

class _TeacherNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _TeacherNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

/// Parent Shell Screen with Premium Bottom Navigation
// ─────────────────────────────────────────────────────────────────────────────

class ParentShellScreen extends StatefulWidget {
  final Widget child;

  const ParentShellScreen({super.key, required this.child});

  @override
  State<ParentShellScreen> createState() => _ParentShellScreenState();
}

class _ParentShellScreenState extends State<ParentShellScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;




  // Smart navigation items - الشاشات الأهم لولي الأمر
  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'الرئيسية',
      route: '/parent',
    ),
    _NavItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today_rounded,
      label: 'الجدول',
      route: '/parent/schedule',
    ),
    _NavItem(
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
      label: 'الدرجات',
      route: '/parent/grades',
    ),
    _NavItem(
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      label: 'الإشعارات',
      route: '/parent/notifications',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'حسابي',
      route: '/parent/profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final showDrawer = location == '/parent';

    return Scaffold(
      key: parentScaffoldKey,
      drawer: showDrawer ? const ParentAppDrawer() : null,
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: GeniusBottomNav(
        items: _navItems
            .map((item) => NavItem(icon: item.icon, label: item.label))
            .toList(),
        currentIndex: _calculateSelectedIndex(context),
        onItemSelected: (index) => _onItemTapped(index, context),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/parent/schedule')) return 1;
    if (location.startsWith('/parent/grades')) return 2;
    if (location.startsWith('/parent/notifications')) return 3;
    if (location.startsWith('/parent/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    context.go(_navItems[index].route);
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
