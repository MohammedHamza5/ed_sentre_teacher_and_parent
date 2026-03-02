import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/models.dart';
import '../base_repository.dart';

/// Messaging Repository Mixin
/// Handles conversations, messages, and realtime subscriptions
mixin MessagingRepositoryMixin on BaseRepository {
  SupabaseClient get client;
  String? get currentUserId;

  // ═══════════════════════════════════════════════════════════════════════
  // CONVERSATIONS
  // ═══════════════════════════════════════════════════════════════════════

  /// Get conversations (student perspective)
  Future<List<ConversationModel>> getConversations(String centerId) async {
    final response = await client.rpc(
      'get_student_conversations',
      params: {'p_center_id': centerId},
    );

    return (response as List)
        .map((e) => ConversationModel.fromJson(e))
        .toList();
  }

  /// Get teacher conversations
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
          students:student_id(
            id,
            user_id,
            users(full_name, avatar_url)
          )
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
      final student = e['students'] as Map<String, dynamic>?;
      final user = student?['users'] as Map<String, dynamic>?;

      return ConversationModel.fromJson({
        ...e,
        'student_name': user?['full_name'] ?? 'طالب',
        'student_avatar': user?['avatar_url'],
      });
    }).toList();
  }

  /// Get parent conversations with teachers
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

    // 2. Get students' table IDs (conversations use table ID usually, or user ID? check schema)
    // The previous code in MessagingRepositoryMixin uses student_id which seems to be table ID in getTeacherConversations join
    // But getTeacherConversations joins `students:student_id`.
    // Let's verify what student_id is in conversations table.
    // In getTeacherConversations: students:student_id (id, user_id).
    // So conversations.student_id is the table ID.
    // We have student_user_ids. Need to get student table IDs.

    final studentsResponse = await client
        .from('students')
        .select('id')
        .inFilter('user_id', studentIds);
    final studentTableIds = (studentsResponse as List)
        .map((s) => s['id'])
        .toList();

    if (studentTableIds.isEmpty) return [];

    // 3. Fetch conversations
    final response = await client
        .from('conversations')
        .select('''
          *,
          teachers:teacher_id(
            id,
            user_id,
            users:user_id(full_name, avatar_url)
          )
        ''')
        .inFilter('student_id', studentTableIds)
        .eq('center_id', centerId)
        .order('updated_at', ascending: false);

    return (response as List).map((e) {
      final teacher = e['teachers'] as Map<String, dynamic>?;
      final user = teacher?['users'] as Map<String, dynamic>?;

      return ConversationModel.fromJson({
        ...e,
        'teacher_name': user?['full_name'] ?? 'معلم',
        'teacher_avatar': user?['avatar_url'],
      });
    }).toList();
  }

  /// Create or get conversation (two overloads merged)
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
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Create conversation (teacher-initiated)
  Future<String> createConversation({
    required String studentId,
    required String centerId,
  }) async {
    final userId = currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final existing = await client
        .from('conversations')
        .select('id')
        .eq('teacher_id', userId)
        .eq('student_id', studentId)
        .eq('center_id', centerId)
        .maybeSingle();

    if (existing != null) {
      return existing['id'] as String;
    }

    final response = await client
        .from('conversations')
        .insert({
          'teacher_id': userId,
          'student_id': studentId,
          'center_id': centerId,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    return response['id'] as String;
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

    await client
        .from('conversations')
        .update({
          'last_message': content,
          'last_message_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // REALTIME SUBSCRIPTIONS
  // ═══════════════════════════════════════════════════════════════════════

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
