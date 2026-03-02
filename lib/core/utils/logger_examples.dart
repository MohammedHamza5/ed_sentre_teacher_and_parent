/// أمثلة على استخدام AppLogger
/// يوضح كل طريقة للتسجيل
library;

import 'app_logger.dart';

// ═══════════════════════════════════════════════════════════════════════════
// أمثلة الاستخدام
// ═══════════════════════════════════════════════════════════════════════════

class LoggerExamples {
  /// مثال 1: معلومات عامة
  void exampleInfo() {
    log.info('User opened home screen', tag: 'Navigation');
    log.info('Settings loaded successfully', tag: 'Settings');
  }

  /// مثال 2: تحذيرات
  void exampleWarnings() {
    log.warning(
      'Cache is getting full',
      tag: 'Cache',
      data: {'current_size': '8MB', 'max_size': '10MB'},
    );

    log.warning('User tried invalid action', tag: 'UI');
  }

  /// مثال 3: أخطاء
  void exampleErrors() {
    try {
      throw Exception('Network request failed');
    } catch (e, stackTrace) {
      log.error(
        'Failed to fetch user data',
        tag: 'API',
        error: e,
        stackTrace: stackTrace,
        data: {'user_id': '123', 'endpoint': '/api/users/123'},
      );
    }
  }

  /// مثال 4: قياس الأداء
  void examplePerformance() async {
    // طريقة 1: يدوياً
    final timer = PerformanceTimer('Load Dashboard Data');
    await Future.delayed(const Duration(milliseconds: 500));
    timer.stop(); // سيسجل تلقائياً

    // طريقة 2: مع دالة
    await measurePerformance('Fetch User Profile', () async {
      await Future.delayed(const Duration(milliseconds: 200));
    });
  }

  /// مثال 5: طلبات الشبكة
  void exampleNetwork() {
    // نجاح
    log.network(
      'User login successful',
      tag: 'Auth',
      url: 'https://api.example.com/auth/login',
      method: 'POST',
      statusCode: 200,
      requestData: {
        'email': 'user@example.com',
        // password سيتم إخفاؤه تلقائياً
      },
      responseData: {
        'user_id': '123',
        'token': '***', // سيتم إخفاؤه تلقائياً
      },
    );

    // فشل
    log.network(
      'Failed to load students',
      tag: 'API',
      url: 'https://api.example.com/students',
      method: 'GET',
      statusCode: 500,
    );
  }

  /// مثال 6: قاعدة البيانات
  void exampleDatabase() {
    log.database(
      'Inserted new student',
      tag: 'DB',
      query: 'INSERT INTO students (name, email) VALUES (?, ?)',
      params: {'name': 'أحمد', 'email': 'ahmed@example.com'},
      result: {'id': 123, 'rows_affected': 1},
    );

    log.database(
      'Fetched assignments',
      tag: 'DB',
      query: 'SELECT * FROM assignments WHERE teacher_id = ?',
      params: {'teacher_id': '456'},
      result: {'count': 5},
    );
  }

  /// مثال 7: واجهة المستخدم
  void exampleUI() {
    log.ui(
      'User navigated to assignments screen',
      screen: 'TeacherAssignmentsScreen',
      data: {
        'from_screen': 'TeacherHomeScreen',
        'navigation_type': 'bottom_nav',
      },
    );

    log.ui(
      'Button clicked',
      tag: 'Interaction',
      data: {'button': 'create_assignment', 'screen': 'AssignmentsScreen'},
    );
  }

  /// مثال 8: مصادقة
  void exampleAuth() {
    log.auth(
      'User logged in',
      userId: '123',
      action: 'login',
      data: {'method': 'email_password', 'device': 'Android'},
    );

    log.auth('Session refreshed', userId: '123', action: 'refresh_token');

    log.auth('User logged out', userId: '123', action: 'logout');
  }

  /// مثال 9: بيانات
  void exampleData() {
    log.data(
      'Loaded teacher groups',
      tag: 'TeacherProvider',
      data: {
        'teacher_id': '456',
        'groups_count': 3,
        'groups': [
          {'id': 1, 'name': 'الصف الأول'},
          {'id': 2, 'name': 'الصف الثاني'},
        ],
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// أمثلة متقدمة
// ═══════════════════════════════════════════════════════════════════════════

/// مثال: تتبع دورة حياة الشاشة
class ScreenLifecycleLogger {
  final String screenName;

  ScreenLifecycleLogger(this.screenName);

  void onInit() {
    log.ui('Screen initialized', screen: screenName, tag: 'Lifecycle');
  }

  void onBuild() {
    log.debug('Screen built', tag: screenName);
  }

  void onDispose() {
    log.ui('Screen disposed', screen: screenName, tag: 'Lifecycle');
  }
}

/// مثال: تتبع العمليات المتسلسلة
class WorkflowLogger {
  final String workflowName;
  final List<String> _steps = [];

  WorkflowLogger(this.workflowName) {
    log.info('Workflow started: $workflowName', tag: 'Workflow');
  }

  void step(String stepName) {
    _steps.add(stepName);
    log.debug(
      'Workflow step: $stepName',
      tag: workflowName,
      data: {'step_number': _steps.length, 'total_steps': _steps.length},
    );
  }

  void complete({bool success = true}) {
    log.info(
      'Workflow ${success ? 'completed' : 'failed'}: $workflowName',
      tag: 'Workflow',
      data: {'success': success, 'total_steps': _steps.length, 'steps': _steps},
    );
  }
}

/// مثال: تتبع حالات Provider
mixin ProviderLogger {
  String get providerName;

  void logStateChange(String change, {Map<String, dynamic>? data}) {
    log.data('State changed: $change', tag: providerName, data: data);
  }

  void logAction(String action, {Map<String, dynamic>? data}) {
    log.info('Action: $action', tag: providerName, data: data);
  }

  void logError(String message, dynamic error, [StackTrace? stackTrace]) {
    log.error(message, tag: providerName, error: error, stackTrace: stackTrace);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// استخدام حقيقي في التطبيق
// ═══════════════════════════════════════════════════════════════════════════

/// مثال: AuthProvider مع Logging
/*
class AuthProvider with ChangeNotifier, ProviderLogger {
  @override
  String get providerName => 'AuthProvider';

  Future<void> signIn(String email, String password) async {
    logAction('Sign in attempt', data: {'email': email});

    try {
      final timer = PerformanceTimer('Sign In', tag: providerName);
      
      // محاولة تسجيل الدخول
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      timer.stop();
      
      if (response.user != null) {
        logStateChange('User signed in', data: {
          'user_id': response.user!.id,
        });
        log.auth('User logged in', userId: response.user!.id);
      }
      
      notifyListeners();
    } catch (e, stackTrace) {
      logError('Sign in failed', e, stackTrace);
      rethrow;
    }
  }
}
*/

/// مثال: Repository مع Logging
/*
class UserRepository {
  Future<User> getUser(String id) async {
    log.info('Fetching user', tag: 'UserRepository', data: {'user_id': id});

    return measurePerformance('Get User $id', () async {
      final response = await _client.from('users').select().eq('id', id).single();
      
      log.database(
        'User fetched',
        query: 'SELECT * FROM users WHERE id = ?',
        params: {'id': id},
        result: response,
      );

      return User.fromJson(response);
    });
  }
}
*/

/// مثال: Screen مع Logging
/*
class TeacherHomeScreen extends StatefulWidget {
  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final _lifecycle = ScreenLifecycleLogger('TeacherHomeScreen');

  @override
  void initState() {
    super.initState();
    _lifecycle.onInit();
    _loadData();
  }

  Future<void> _loadData() async {
    log.ui('Loading dashboard data', screen: 'TeacherHomeScreen');
    
    await measurePerformance('Load Dashboard', () async {
      // تحميل البيانات
      await Future.delayed(const Duration(seconds: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    _lifecycle.onBuild();
    return Scaffold(...);
  }

  @override
  void dispose() {
    _lifecycle.onDispose();
    super.dispose();
  }
}
*/
