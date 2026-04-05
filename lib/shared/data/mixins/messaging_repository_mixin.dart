import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/models.dart';
import '../base_repository.dart';

/// Messaging Repository Mixin
/// Handles conversations, messages, and realtime subscriptions
/// Supports two conversation types:
///   - student_teacher: Student and Teacher can send. Parent can view only.
///   - parent_teacher: Parent and Teacher can send. Student cannot see.
mixin MessagingRepositoryMixin on BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  // ═══════════════════════════════════════════════════════════════════════
  // CONVERSATIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get conversations (student perspective)
  /// Students only see student_teacher conversations
  Future<List<ConversationModel>> getConversations(String centerId) async {
    final response = await client
        .from('conversations')
        .select('''
          *,
          teacher:users!conversations_teacher_id_fkey(full_name, avatar_url)
        ''')
        .eq('student_id', currentUserId ?? '')
        .eq('center_id', centerId)
        .eq('conversation_type', 'student_teacher')
        .order('updated_at', ascending: false);

    return (response as List).map((e) {
      final teacher = e['teacher'] as Map<String, dynamic>?;
      return ConversationModel.fromJson({
        ...e,
        'teacher_name': teacher?['full_name'] ?? 'معلم',
        'teacher_avatar': teacher?['avatar_url'],
      });
    }).toList();
  }

  /// Get teacher conversations (both types)
  Future<List<ConversationModel>> getTeacherConversations({
    required String centerId,
    int? limit,
    int? offset,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    var query = client
        .from('conversations')
        .select('''
          *,
          student:users!conversations_student_id_fkey(full_name, avatar_url),
          parent:users!conversations_parent_id_fkey(full_name, avatar_url)
        ''')
        .eq('teacher_id', userId)
        .eq('center_id', centerId)
        .order('updated_at', ascending: false);

    if (limit != null && offset != null) {
      query = query.range(offset, offset + limit - 1);
    } else if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;

    return (response as List).map((e) {
      final student = e['student'] as Map<String, dynamic>?;
      final parent = e['parent'] as Map<String, dynamic>?;

      return ConversationModel.fromJson({
        ...e,
        'student_name': student?['full_name'] ?? 'طالب',
        'student_avatar': student?['avatar_url'],
        'parent_name': parent?['full_name'],
        'parent_avatar': parent?['avatar_url'],
      });
    }).toList();
  }

  /// Get parent conversations:
  /// 1. parent_teacher conversations (private, can send)
  /// 2. student_teacher conversations of their children (read-only)
  Future<List<ConversationModel>> getParentConversations({
    required String centerId,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    // 1. Get parent's children IDs
    final parentRecord = await client
        .from('parents')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    final parentId = parentRecord?['id'] ?? userId;

    final linksResponse = await client
        .from('student_parents')
        .select('student_user_id')
        .eq('parent_id', parentId);

    final links = List<Map<String, dynamic>>.from(linksResponse as List);
    if (links.isEmpty) return [];

    final studentIds = links.map((l) => l['student_user_id']).toList();

    // 2. Get parent's private conversations (parent_teacher)
    final privateResponse = await client
        .from('conversations')
        .select('''
          *,
          teacher:users!conversations_teacher_id_fkey(full_name, avatar_url),
          student:users!conversations_student_id_fkey(full_name, avatar_url)
        ''')
        .eq('parent_id', userId)
        .eq('center_id', centerId)
        .eq('conversation_type', 'parent_teacher')
        .order('updated_at', ascending: false);

    final privateConversations = (privateResponse as List).map((e) {
      final teacher = e['teacher'] as Map<String, dynamic>?;
      final student = e['student'] as Map<String, dynamic>?;

      return ConversationModel.fromJson({
        ...e,
        'teacher_name': teacher?['full_name'] ?? 'معلم',
        'teacher_avatar': teacher?['avatar_url'],
        'student_name': student?['full_name'] ?? 'طالب',
        'student_avatar': student?['avatar_url'],
      });
    }).toList();

    // 3. Get children's student_teacher conversations (read-only)
    final childrenResponse = await client
        .from('conversations')
        .select('''
          *,
          teacher:users!conversations_teacher_id_fkey(full_name, avatar_url),
          student:users!conversations_student_id_fkey(full_name, avatar_url)
        ''')
        .inFilter('student_id', studentIds)
        .eq('center_id', centerId)
        .eq('conversation_type', 'student_teacher')
        .order('updated_at', ascending: false);

    final readOnlyConversations = (childrenResponse as List).map((e) {
      final teacher = e['teacher'] as Map<String, dynamic>?;
      final student = e['student'] as Map<String, dynamic>?;

      return ConversationModel.fromJson(
        {
          ...e,
          'teacher_name': teacher?['full_name'] ?? 'معلم',
          'teacher_avatar': teacher?['avatar_url'],
          'student_name': student?['full_name'] ?? 'طالب',
          'student_avatar': student?['avatar_url'],
        },
        isReadOnly: true,
      );
    }).toList();

    // Combine: private first, then read-only
    return [...privateConversations, ...readOnlyConversations];
  }

  /// Create or get a student_teacher conversation
  Future<String> getOrCreateConversation({
    required String studentId,
    required String teacherId,
    required String centerId,
  }) async {
    final existing = await client
        .from('conversations')
        .select('id')
        .eq('student_id', studentId)
        .eq('teacher_id', teacherId)
        .eq('center_id', centerId)
        .eq('conversation_type', 'student_teacher')
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    final response = await client
        .from('conversations')
        .insert({
          'student_id': studentId,
          'teacher_id': teacherId,
          'center_id': centerId,
          'conversation_type': 'student_teacher',
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Create student_teacher conversation (teacher-initiated)
  Future<String> createConversation({
    required String studentId,
    required String centerId,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');

    return getOrCreateConversation(
      studentId: studentId,
      teacherId: userId,
      centerId: centerId,
    );
  }

  /// Create or get a parent_teacher conversation
  Future<String> getOrCreateParentConversation({
    required String parentUserId,
    required String teacherId,
    required String studentId,
    required String centerId,
  }) async {
    final existing = await client
        .from('conversations')
        .select('id')
        .eq('parent_id', parentUserId)
        .eq('teacher_id', teacherId)
        .eq('student_id', studentId)
        .eq('center_id', centerId)
        .eq('conversation_type', 'parent_teacher')
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    final response = await client
        .from('conversations')
        .insert({
          'parent_id': parentUserId,
          'teacher_id': teacherId,
          'student_id': studentId,
          'center_id': centerId,
          'conversation_type': 'parent_teacher',
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Create parent_teacher conversation (parent-initiated)
  Future<String> createParentConversation({
    required String teacherId,
    required String studentId,
    required String centerId,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');

    return getOrCreateParentConversation(
      parentUserId: userId,
      teacherId: teacherId,
      studentId: studentId,
      centerId: centerId,
    );
  }

  /// Get teachers for a parent's children (for starting new chats)
  Future<List<Map<String, dynamic>>> getParentChildrenTeachers({
    required String centerId,
  }) async {
    final userId = currentUserId;
    if (userId == null) return [];

    final parentRecord = await client
        .from('parents')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    final parentId = parentRecord?['id'] ?? userId;

    final linksResponse = await client
        .from('student_parents')
        .select('student_user_id')
        .eq('parent_id', parentId);

    final links = List<Map<String, dynamic>>.from(linksResponse as List);
    if (links.isEmpty) return [];

    final studentIds = links.map((l) => l['student_user_id']).toList();

    // Get enrollments for all children to find their teachers
    final enrollments = await client
        .from('student_group_enrollments')
        .select('''
          student_id,
          groups!inner(
            id,
            name,
            teacher_id,
            course_id,
            courses(name)
          )
        ''')
        .inFilter('student_id', studentIds);

    // Build a list of teacher+student combinations
    final results = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final enrollment in (enrollments as List)) {
      final group = enrollment['groups'] as Map<String, dynamic>?;
      if (group == null) continue;

      final teacherUserId = group['teacher_id'] as String?;
      final studentUserId = enrollment['student_id'] as String?;
      if (teacherUserId == null || studentUserId == null) continue;

      final key = '$teacherUserId-$studentUserId';
      if (seen.contains(key)) continue;
      seen.add(key);

      // Get teacher and student names
      final teacherUser = await client
          .from('users')
          .select('full_name, avatar_url')
          .eq('id', teacherUserId)
          .maybeSingle();

      final studentUser = await client
          .from('users')
          .select('full_name, avatar_url')
          .eq('id', studentUserId)
          .maybeSingle();

      results.add({
        'teacher_id': teacherUserId,
        'teacher_name': teacherUser?['full_name'] ?? 'معلم',
        'teacher_avatar': teacherUser?['avatar_url'],
        'student_id': studentUserId,
        'student_name': studentUser?['full_name'] ?? 'طالب',
        'student_avatar': studentUser?['avatar_url'],
        'course_name': (group['courses'] as Map?)?['name'],
      });
    }

    return results;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MESSAGES
  // ═══════════════════════════════════════════════════════════════════════

  /// Get messages for a conversation
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int? limit,
    int? offset,
    bool ascending = true,
  }) async {
    final userId = currentUserId;
    var query = client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: ascending);
    if (limit != null && offset != null) {
      query = query.range(offset, offset + limit - 1);
    } else if (limit != null) {
      query = query.limit(limit);
    }
    final response = await query;

    return (response as List)
        .map((e) => MessageModel.fromJson(e, currentUserId: userId))
        .toList();
  }

  /// Send message
  /// NOTE: The DB trigger `on_new_message` handles updating last_message,
  /// last_message_at, updated_at, and incrementing unread counts automatically.
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
    String? fileUrl,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    await client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'content': content,
      'message_type': type.name,
      'file_url': fileUrl,
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REALTIME SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      await client.rpc(
        'mark_messages_read',
        params: {'p_conversation_id': conversationId},
      );
    } catch (_) {}
  }

  /// Subscribe to messages
  RealtimeChannel subscribeToMessages(
    String conversationId,
    void Function(MessageModel) onMessage,
  ) {
    return client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            onMessage(
              MessageModel.fromJson(
                payload.newRecord,
                currentUserId: currentUserId,
              ),
            );
          },
        )
        .subscribe();
  }

  /// Unsubscribe from channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }
}
