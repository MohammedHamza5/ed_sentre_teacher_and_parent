import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  static Future<void> show(BuildContext context, {
    required String studentId, 
    required String studentName,
    required String sessionId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<StudentActionCubit>()..fetchStatus(studentId),
        child: StudentActionBottomSheet(
          studentId: studentId, 
          studentName: studentName,
          sessionId: sessionId,
        ),
      ),
    );
  }

  @override
  State<StudentActionBottomSheet> createState() => _StudentActionBottomSheetState();
}

class _StudentActionBottomSheetState extends State<StudentActionBottomSheet> {
  double _paidAmount = 0.0;
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.studentName, 
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), 
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          BlocConsumer<StudentActionCubit, StudentActionState>(
            listener: (context, state) {
              if (state is StudentActionSuccess) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تسجيل الحضور بنجاح'), backgroundColor: Colors.green)
                );
              } else if (state is StudentActionFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message), backgroundColor: Colors.red)
                );
              }
            },
            builder: (context, state) {
              if (state is StudentActionLoading) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              if (state is StudentActionStatusLoaded) {
                return _buildStatusContent(context, state);
              }
              
              if (state is StudentActionProcessing) {
                return const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              
              return const SizedBox();
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStatusContent(BuildContext context, StudentActionStatusLoaded state) {
    return Column(
      children: [
        if (state.hasDebt) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1), 
              borderRadius: BorderRadius.circular(12), 
              border: Border.all(color: Colors.red.withOpacity(0.5))
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'يوجد مستحقات مالية (${state.monthYear})\nالمطلوب: ${state.debtAmount} ج.م', 
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                  )
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'المبلغ المدفوع الآن', 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
              suffixText: 'ج.م',
              prefixIcon: const Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
            onChanged: (val) => _paidAmount = double.tryParse(val) ?? 0.0,
          ),
          const SizedBox(height: 24),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1), 
              borderRadius: BorderRadius.circular(12), 
              border: Border.all(color: Colors.green.withOpacity(0.5))
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'الوضع المالي سليم، يسمح بالدخول.', 
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                  )
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56), 
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            context.read<StudentActionCubit>().recordAction(
              studentId: widget.studentId,
              sessionId: widget.sessionId,
              invoiceId: state.hasDebt && _paidAmount > 0 ? state.invoiceId : null,
              paidAmount: state.hasDebt && _paidAmount > 0 ? _paidAmount : null,
            );
          },
          child: const Text('تأكيد وتسجيل الحضور', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }
}
