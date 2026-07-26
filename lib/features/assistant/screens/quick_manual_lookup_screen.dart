import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../cubits/manual_lookup/manual_lookup_cubit.dart';
import '../cubits/manual_lookup/manual_lookup_state.dart';
import '../../../../features/auth/provider/auth_provider.dart';
import '../../../domain/repositories/assistant_repository.dart';
import '../widgets/student_action_bottom_sheet.dart';

class QuickManualLookupScreen extends StatefulWidget {
  const QuickManualLookupScreen({super.key});

  @override
  State<QuickManualLookupScreen> createState() => _QuickManualLookupScreenState();
}

class _QuickManualLookupScreenState extends State<QuickManualLookupScreen> {
  late final ManualLookupCubit _cubit;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final centerId = context.read<AuthProvider>().currentUser?.defaultCenterId ?? '';
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
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _cubit.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('البحث اليدوي السريع'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث برقم الهاتف أو الاسم (3 أحرف على الأقل)...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _cubit.search('');
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            Expanded(
              child: BlocBuilder<ManualLookupCubit, ManualLookupState>(
                builder: (context, state) {
                  if (state is ManualLookupInitial) {
                    return const Center(
                      child: Text(
                        'اكتب 3 أحرف أو أرقام على الأقل للبحث', 
                        style: TextStyle(color: Colors.grey, fontSize: 16)
                      )
                    );
                  }
                  if (state is ManualLookupLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ManualLookupError) {
                    return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
                  }
                  if (state is ManualLookupLoaded) {
                    if (state.results.isEmpty) {
                      return const Center(
                        child: Text(
                          'لا يوجد طالب مطابق للبحث', 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                        )
                      );
                    }
                    return ListView.separated(
                      itemCount: state.results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final student = state.results[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                            child: const Icon(Icons.person),
                          ),
                          title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(student.phone),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          onTap: () {
                            // Placeholder session ID for now
                            const activeSessionId = '00000000-0000-0000-0000-000000000000';
                            StudentActionBottomSheet.show(
                              context,
                              studentId: student.id,
                              studentName: student.fullName,
                              sessionId: activeSessionId,
                            );
                          },
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
}
