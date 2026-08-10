import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';
import '../presentation/cubits/manual_lookup/manual_lookup_cubit.dart';
import '../presentation/cubits/manual_lookup/manual_lookup_state.dart';
import '../../../../features/auth/provider/auth_provider.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/drawer/drawer_logout_dialog.dart';
import '../domain/repositories/assistant_repository.dart';
import '../presentation/widgets/student_action_bottom_sheet.dart';

class QuickManualLookupScreen extends StatefulWidget {
  const QuickManualLookupScreen({super.key});

  @override
  State<QuickManualLookupScreen> createState() =>
      _QuickManualLookupScreenState();
}

class _QuickManualLookupScreenState extends State<QuickManualLookupScreen> {
  late final ManualLookupCubit _cubit;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final centerId =
        context.read<AuthProvider>().currentUser?.defaultCenterId ?? '';
    _cubit = ManualLookupCubit(GetIt.I<AssistantRepository>(), centerId);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _cubit.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'القائمة',
            onPressed: openAssistantDrawer,
          ),
          title: const Text(
            'البحث اليدوي السريع',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              tooltip: 'تسجيل الخروج',
              onPressed: () => confirmDrawerLogout(
                context,
                context.read<AuthProvider>(),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar Container
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color:
                    theme.appBarTheme.backgroundColor ??
                    theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText:
                      'ابحث برقم الهاتف أو اسم الطالب (3 أحرف على الأقل)...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                  prefixIcon: Icon(
                    Icons.person_search_rounded,
                    color: colorScheme.primary,
                    size: 26,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _cubit.search('');
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.15),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onChanged: (val) {
                  setState(() {});
                  _onSearchChanged(val);
                },
              ),
            ),

            // Search Results
            Expanded(
              child: BlocBuilder<ManualLookupCubit, ManualLookupState>(
                builder: (context, state) {
                  if (state is ManualLookupInitial) {
                    return _buildEmptyState(
                      icon: Icons.manage_search_rounded,
                      title: 'جاهز لبدء البحث',
                      subtitle:
                          'قم بكتابة جزء من اسم الطالب أو رقم هاتفه للوصول الفوري وتسجيل الحضور.',
                      colorScheme: colorScheme,
                      theme: theme,
                    );
                  }
                  if (state is ManualLookupLoading) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'جاري البحث عن الطلاب...',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is ManualLookupError) {
                    return _buildEmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'حدث خطأ أثناء البحث',
                      subtitle: state.message,
                      colorScheme: colorScheme,
                      theme: theme,
                      isError: true,
                    );
                  }
                  if (state is ManualLookupLoaded) {
                    if (state.results.isEmpty) {
                      return _buildEmptyState(
                        icon: Icons.person_off_outlined,
                        title: 'لا يوجد طالب مطابق',
                        subtitle:
                            'لم نعثر على أي طالب بهذا الاسم أو الهاتف في هذا السنتر.',
                        colorScheme: colorScheme,
                        theme: theme,
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final student = state.results[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                const activeSessionId =
                                    '00000000-0000-0000-0000-000000000000';
                                StudentActionBottomSheet.show(
                                  context,
                                  studentId: student.id,
                                  studentName: student.fullName,
                                  sessionId: activeSessionId,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: colorScheme.primary
                                          .withValues(alpha: 0.12),
                                      child: Text(
                                        student.fullName.isNotEmpty
                                            ? student.fullName[0].toUpperCase()
                                            : '؟',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student.fullName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.phone_android_rounded,
                                                size: 14,
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 0.5),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                student.phone.isNotEmpty
                                                    ? student.phone
                                                    : 'بدون رقم',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.6),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.how_to_reg_rounded,
                                        color: colorScheme.primary,
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme colorScheme,
    required ThemeData theme,
    bool isError = false,
  }) {
    final color = isError ? const Color(0xFFEF4444) : colorScheme.primary;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
