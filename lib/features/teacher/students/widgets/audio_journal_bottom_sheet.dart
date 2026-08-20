import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/config/app_colors.dart';
import '../services/audio_journal_local_service.dart';

class AudioJournalBottomSheet extends StatefulWidget {
  final Map<String, dynamic> student;

  const AudioJournalBottomSheet({super.key, required this.student});

  @override
  State<AudioJournalBottomSheet> createState() => _AudioJournalBottomSheetState();
}

class _AudioJournalBottomSheetState extends State<AudioJournalBottomSheet>
    with SingleTickerProviderStateMixin {
  final _service = AudioJournalLocalService();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;

  // Recording state
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _timer;
  
  // Playing state
  String? _currentlyPlayingId;

  // Animation for pulse effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadNotes();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _currentlyPlayingId = null);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final studentId = widget.student['student_id']?.toString() ??
        widget.student['id']?.toString() ??
        '';

    if (studentId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final notes = await _service.getNotesForStudent(studentId);
    setState(() {
      _notes = notes.reversed.toList(); // Newest first
      _isLoading = false;
    });
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _recordingSeconds = 0;
        });
        
        _pulseController.repeat(reverse: true);
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordingSeconds++;
            });
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('يجب السماح بصلاحية الميكروفون')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _pulseController.stop();
    
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);

    if (path != null && _recordingSeconds > 0) {
      final studentId = widget.student['student_id']?.toString() ??
          widget.student['id']?.toString() ??
          '';

      await _service.saveNote(
        studentId: studentId,
        title: 'ملاحظة صوتية سريعة',
        durationSeconds: _recordingSeconds,
        filePath: path,
      );

      _loadNotes(); // Reload notes
    }
    _recordingSeconds = 0;
  }
  
  Future<void> _playPauseAudio(String noteId, String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    
    if (_currentlyPlayingId == noteId) {
      await _audioPlayer.pause();
      setState(() => _currentlyPlayingId = null);
    } else {
      if (_currentlyPlayingId != null) {
        await _audioPlayer.stop();
      }
      setState(() => _currentlyPlayingId = noteId);
      await _audioPlayer.play(DeviceFileSource(filePath));
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatDate(String isoDate) {
    try {
      final d = DateTime.parse(isoDate);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentName = widget.student['student_name']?.toString() ??
        widget.student['name']?.toString() ??
        'طالب';

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          children: [
            // Header
            Center(
              child: Container(
                width: 45.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                CircleAvatar(
                  radius: 22.r,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Icon(Icons.mic, color: AppColors.primary),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'النوتة الصوتية السريعة',
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                      Text(
                        studentName,
                        style: TextStyle(
                            fontSize: 12.sp, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Notes List
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _notes.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد ملاحظات صوتية لهذا الطالب بعد.',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _notes.length,
                          separatorBuilder: (c, i) => SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            final note = _notes[index];
                            return _buildNoteCard(note);
                          },
                        ),
            ),

            SizedBox(height: 16.h),

            // Recording UI
            if (_isRecording)
              Column(
                children: [
                  Text(
                    _formatDuration(_recordingSeconds),
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'جاري التسجيل...',
                    style: TextStyle(color: AppColors.error),
                  ),
                ],
              ),

            SizedBox(height: 16.h),

            // Record Button
            GestureDetector(
              onTap: _isRecording ? _stopRecording : _startRecording,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isRecording ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording
                            ? AppColors.error.withValues(alpha: 0.2)
                            : AppColors.primary.withValues(alpha: 0.2),
                      ),
                      child: Center(
                        child: Container(
                          width: 60.w,
                          height: 60.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isRecording
                                ? AppColors.error
                                : AppColors.primary,
                          ),
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            color: Colors.white,
                            size: 32.sp,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final isPlaying = _currentlyPlayingId == note['id'];
    final isTextNote = (note['duration_seconds'] ?? 0) == 0;
    
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (!isTextNote) {
                _playPauseAudio(note['id'], note['file_path']);
              }
            },
            child: CircleAvatar(
              backgroundColor: isTextNote 
                  ? Colors.blue.withValues(alpha: 0.1) 
                  : AppColors.primary.withValues(alpha: 0.1),
              child: Icon(
                isTextNote 
                    ? Icons.description 
                    : (isPlaying ? Icons.pause : Icons.play_arrow),
                color: isTextNote ? Colors.blue : AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note['title'] ?? 'ملاحظة صوتية',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    if (!isTextNote) ...[
                      Icon(Icons.access_time,
                          size: 12.sp, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      SizedBox(width: 4.w),
                      Text(
                        _formatDuration(note['duration_seconds'] ?? 0),
                        style: TextStyle(
                            fontSize: 12.sp, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                      ),
                      SizedBox(width: 16.w),
                    ],
                    Icon(Icons.calendar_today,
                        size: 12.sp, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                    SizedBox(width: 4.w),
                    Text(
                      _formatDate(note['date'] ?? ''),
                      style: TextStyle(
                          fontSize: 12.sp, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () async {
              await _service.deleteNote(note['id']);
              _loadNotes();
            },
          )
        ],
      ),
    );
  }
}
