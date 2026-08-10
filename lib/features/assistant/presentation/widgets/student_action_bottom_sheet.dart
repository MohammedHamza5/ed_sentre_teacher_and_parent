import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/providers/center_provider.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../cubits/student_action/student_action_cubit.dart';
import '../cubits/student_action/student_action_state.dart';

class StudentActionBottomSheet extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String sessionId;

  const StudentActionBottomSheet({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.sessionId,
  });

  static Future<void> show(
    BuildContext context, {
    required String studentId,
    required String studentName,
    required String sessionId,
  }) {
    StudentActionCubit? existingCubit;
    try {
      existingCubit = context.read<StudentActionCubit>();
    } catch (_) {}

    final authProvider = () {
      try {
        return context.read<AuthProvider>();
      } catch (_) {
        return null;
      }
    }();

    final centerProvider = () {
      try {
        return context.read<CenterProvider>();
      } catch (_) {
        return null;
      }
    }();

    // NOTE: CenterProvider.currentCenterId is the primary source for the teacher/assistant role.
    // defaultCenterId on UserModel is a fallback. If both are null the RPC will reject the call.
    final centerId = centerProvider?.currentCenterId ??
        authProvider?.currentUser?.defaultCenterId ??
        authProvider?.currentUser?.lastSelectedCenterId ??
        '';

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        if (existingCubit != null) {
          return BlocProvider.value(
            value: existingCubit..fetchStatus(studentId),
            child: StudentActionBottomSheet(
              studentId: studentId,
              studentName: studentName,
              sessionId: sessionId,
            ),
          );
        }

        return BlocProvider(
          create: (_) => StudentActionCubit(
            GetIt.I<AssistantRepository>(),
            centerId,
          )..fetchStatus(studentId),
          child: StudentActionBottomSheet(
            studentId: studentId,
            studentName: studentName,
            sessionId: sessionId,
          ),
        );
      },
    );
  }

  @override
  State<StudentActionBottomSheet> createState() =>
      _StudentActionBottomSheetState();
}

class _StudentActionBottomSheetState extends State<StudentActionBottomSheet> {
  final TextEditingController _paymentController = TextEditingController();
  double _paidAmount = 0.0;

  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  void _setPaymentAmount(double amount) {
    setState(() {
      _paidAmount = amount;
      _paymentController.text = amount.toStringAsFixed(
        amount.truncateToDouble() == amount ? 0 : 2,
      );
    });
  }

  void _addPaymentAmount(double delta) {
    _setPaymentAmount(_paidAmount + delta);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: bottomInset + 24,
            left: 20,
            right: 20,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull Bar / Handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Student Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.studentName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'تسجيل الحضور السريع',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Status Content
              BlocConsumer<StudentActionCubit, StudentActionState>(
                listener: (context, state) {
                  if (state is StudentActionSuccess) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'تم تسجيل الحضور بنجاح',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } else if (state is StudentActionFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                state.message,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFFEF4444),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is StudentActionLoading ||
                      state is StudentActionProcessing) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48.0),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            state is StudentActionProcessing
                                ? 'جاري تسجيل الحضور...'
                                : 'جاري التحقق من الوضع المالي...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is StudentActionFailure) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFEF4444),
                              size: 36,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'تعذّر التحقق من بيانات الطالب',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEF4444),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.message,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => context
                                  .read<StudentActionCubit>()
                                  .fetchStatus(widget.studentId),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('إعادة المحاولة'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 44),
                                foregroundColor: colorScheme.primary,
                                side: BorderSide(
                                  color: colorScheme.primary.withValues(alpha: 0.4),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is StudentActionStatusLoaded) {
                    return _buildStatusContent(context, state, colorScheme);
                  }

                  return const SizedBox(height: 24);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusContent(
    BuildContext context,
    StudentActionStatusLoaded state,
    ColorScheme colorScheme,
  ) {
    const errorColor = Color(0xFFEF4444);
    const successColor = Color(0xFF10B981);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.hasDebt) ...[
          // Warning Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: errorColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: errorColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: errorColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: errorColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'يوجد مستحقات مالية (${state.monthYear})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: errorColor.withValues(alpha: 0.9),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'المطلوب: ${state.debtAmount} ج.م',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: errorColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Payment Field & Quick Action Buttons
          Text(
            'سداد الرسوم الآن (اختياري)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _paymentController,
            decoration: InputDecoration(
              hintText: 'أدخل المبلغ المدفوع الآن...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              suffixText: 'ج.م',
              prefixIcon: const Icon(Icons.payments_outlined),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) =>
                setState(() => _paidAmount = double.tryParse(val) ?? 0.0),
          ),
          const SizedBox(height: 12),

          // Quick One-Tap Payment Pills (High-Volume Queue Processing helper)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip(
                  label: 'سداد الكامل (${state.debtAmount} ج.م)',
                  onTap: () => _setPaymentAmount(state.debtAmount),
                  colorScheme: colorScheme,
                  isPrimary: true,
                ),
                const SizedBox(width: 8),
                _buildQuickChip(
                  label: '+50 ج.م',
                  onTap: () => _addPaymentAmount(50),
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 8),
                _buildQuickChip(
                  label: '+100 ج.م',
                  onTap: () => _addPaymentAmount(100),
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: 8),
                _buildQuickChip(
                  label: 'تصفير (0)',
                  onTap: () => _setPaymentAmount(0),
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ] else ...[
          // Success Card (No Debt)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: successColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: successColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: successColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: successColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الوضع المالي سليم 100%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: successColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'لا توجد أي مديونيات متأخرة، يرجى السماح بالدخول.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],

        // Submit Action Button (Minimum Tap Target >= 48x48)
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 2,
            shadowColor: colorScheme.primary.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () {
            context.read<StudentActionCubit>().recordAction(
              studentId: widget.studentId,
              sessionId: widget.sessionId,
              invoiceId: state.hasDebt && _paidAmount > 0
                  ? state.invoiceId
                  : null,
              paidAmount: state.hasDebt && _paidAmount > 0 ? _paidAmount : null,
            );
          },
          icon: const Icon(Icons.how_to_reg_rounded, size: 24),
          label: const Text(
            'تأكيد وتسجيل الحضور الآن',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChip({
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    bool isPrimary = false,
  }) {
    return Material(
      color: isPrimary
          ? colorScheme.primary.withValues(alpha: 0.12)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPrimary
                  ? colorScheme.primary.withValues(alpha: 0.4)
                  : colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
              color: isPrimary
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }
}
