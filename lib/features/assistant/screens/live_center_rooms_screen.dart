import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
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
    final centerId =
        context.read<AuthProvider>().currentUser?.defaultCenterId ?? '';
    _cubit = LiveRoomsCubit(GetIt.I<AssistantRepository>(), centerId)
      ..fetchLiveRooms();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'حالة القاعات المباشرة',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'تحديث البيانات',
              onPressed: () => _cubit.fetchLiveRooms(),
            ),
          ],
        ),
        body: BlocBuilder<LiveRoomsCubit, LiveRoomsState>(
          builder: (context, state) {
            if (state is LiveRoomsLoading) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'جاري التآزر مع القاعات الحية...',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              );
            }
            if (state is LiveRoomsError) {
              return _buildEmptyOrError(
                icon: Icons.error_outline_rounded,
                title: 'تعذر جلب حالة القاعات',
                subtitle: state.message,
                colorScheme: colorScheme,
                theme: theme,
                isError: true,
              );
            }
            if (state is LiveRoomsLoaded) {
              if (state.rooms.isEmpty) {
                return _buildEmptyOrError(
                  icon: Icons.meeting_room_outlined,
                  title: 'لا توجد قاعات متاحة',
                  subtitle:
                      'لم يتم تعريف أو تشغيل أي قاعات في السنتر الحالي حتى الآن.',
                  colorScheme: colorScheme,
                  theme: theme,
                );
              }
              return RefreshIndicator(
                onRefresh: () async => _cubit.fetchLiveRooms(),
                color: colorScheme.primary,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.rooms.length,
                  itemBuilder: (context, index) {
                    final room = state.rooms[index];
                    final capacityRatio = room.capacity > 0
                        ? (room.checkedInCount / room.capacity).clamp(0.0, 1.0)
                        : 0.0;
                    const occupiedColor = Color(0xFF10B981);
                    final statusColor = room.isOccupied
                        ? occupiedColor
                        : colorScheme.onSurface.withOpacity(0.4);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: room.isOccupied
                              ? occupiedColor.withOpacity(0.4)
                              : colorScheme.outline.withOpacity(0.12),
                          width: room.isOccupied ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (room.isOccupied ? occupiedColor : Colors.black)
                                    .withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Room Header & Badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.door_front_door_outlined,
                                      color: room.isOccupied
                                          ? occupiedColor
                                          : colorScheme.primary,
                                      size: 26,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      room.roomName,
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        room.isOccupied
                                            ? 'مشغولة حالياً'
                                            : 'قاعة شاغرة',
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            Divider(
                              height: 1,
                              color: colorScheme.outline.withOpacity(0.1),
                            ),
                            const SizedBox(height: 16),

                            if (room.isOccupied) ...[
                              // Teacher & Group Info
                              _buildInfoRow(
                                icon: Icons.person_rounded,
                                label: 'المعلم:',
                                value: room.teacherName,
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(height: 10),
                              _buildInfoRow(
                                icon: Icons.class_rounded,
                                label: 'المجموعة:',
                                value: room.groupName,
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(height: 16),

                              // Capacity Bar
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.groups_rounded,
                                            size: 18,
                                            color: colorScheme.onSurface
                                                .withOpacity(0.6),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'معدل الحضور الحالي:',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        '${room.checkedInCount} / ${room.capacity} طالب',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: capacityRatio.toDouble(),
                                      minHeight: 8,
                                      backgroundColor:
                                          colorScheme.surfaceContainerHighest,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        capacityRatio >= 0.9
                                            ? const Color(0xFFEF4444)
                                            : occupiedColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),

                              // Action Button
                              ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'تم ضبط الماسح للعمل على قاعة (${room.roomName})',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: occupiedColor,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                  context.go('/assistant');
                                },
                                icon: const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  size: 22,
                                ),
                                label: const Text(
                                  'تفعيل الماسح السريع لهذه القاعة',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 52),
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.event_seat_outlined,
                                      size: 36,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'لا توجد حصة دراسية نشطة بهذه القاعة حالياً',
                                      style: TextStyle(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.6),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.6),
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : 'غير محدد',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyOrError({
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
                color: color.withOpacity(0.1),
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
                color: colorScheme.onSurface.withOpacity(0.6),
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
