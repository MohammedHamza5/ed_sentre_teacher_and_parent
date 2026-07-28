import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../presentation/cubits/live_rooms/live_rooms_cubit.dart';
import '../presentation/cubits/live_rooms/live_rooms_state.dart';
import '../../../../features/auth/provider/auth_provider.dart';
import '../domain/repositories/assistant_repository.dart';

class LiveCenterRoomsScreen extends StatefulWidget {
  const LiveCenterRoomsScreen({super.key});

  @override
  State<LiveCenterRoomsScreen> createState() => _LiveCenterRoomsScreenState();
}

class _LiveCenterRoomsScreenState extends State<LiveCenterRoomsScreen> {
  late final LiveRoomsCubit _cubit;

  @override
  void initState() {
    super.initState();
    // Fetch centerId from auth provider
    final centerId = context.read<AuthProvider>().currentUser?.defaultCenterId ?? '';
    // Resolving repository using GetIt directly to avoid import issues
    _cubit = LiveRoomsCubit(GetIt.I<AssistantRepository>(), centerId)..fetchLiveRooms();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حالة القاعات الحية'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _cubit.fetchLiveRooms(),
            )
          ],
        ),
        body: BlocBuilder<LiveRoomsCubit, LiveRoomsState>(
          builder: (context, state) {
            if (state is LiveRoomsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is LiveRoomsError) {
              return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
            }
            if (state is LiveRoomsLoaded) {
              if (state.rooms.isEmpty) {
                return const Center(child: Text('لا يوجد قاعات متاحة في السنتر', style: TextStyle(fontSize: 18)));
              }
              return RefreshIndicator(
                onRefresh: () async => _cubit.fetchLiveRooms(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.rooms.length,
                  itemBuilder: (context, index) {
                    final room = state.rooms[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(room.roomName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: room.isOccupied ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    room.isOccupied ? 'مشغولة حالياً' : 'فارغة',
                                    style: TextStyle(color: room.isOccupied ? Colors.green : Colors.grey[700], fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            if (room.isOccupied) ...[
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.blueGrey, size: 20),
                                  const SizedBox(width: 8),
                                  Text('المعلم: ${room.teacherName}', style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.class_, color: Colors.blueGrey, size: 20),
                                  const SizedBox(width: 8),
                                  Text('المجموعة: ${room.groupName}', style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.group, color: Colors.blueGrey, size: 20),
                                  const SizedBox(width: 8),
                                  Text('الحضور: ${room.checkedInCount} / ${room.capacity} طالب', style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Normally we would pass this room to the Camera Scanner screen using GoRouter or state management
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تحديد قاعة ${room.roomName} للتحضير السريع.')));
                                  },
                                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                                  label: const Text('تفعيل الماسح لهذه القاعة', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              )
                            ] else ...[
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Text('لا توجد حصة نشطة حالياً.', style: TextStyle(color: Colors.grey)),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
