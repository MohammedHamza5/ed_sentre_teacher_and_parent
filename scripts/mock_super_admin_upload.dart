import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Test Script to Mock Super Admin Curriculum Upload
/// Run this with: `dart run scripts/mock_super_admin_upload.dart`
void main() async {
  // Replace these with your actual Supabase URL and Service Role Key or Anon Key
  const supabaseUrl = 'YOUR_SUPABASE_URL';
  const supabaseKey = 'YOUR_SUPABASE_KEY';

  if (supabaseUrl == 'YOUR_SUPABASE_URL') {
    print('Please update the supabaseUrl and supabaseKey in this script before running.');
    return;
  }

  final supabase = SupabaseClient(supabaseUrl, supabaseKey);

  print('1. Creating mock curriculum book record...');
  
  final bookResponse = await supabase.from('curriculum_books').insert({
    'subject_name': 'رياضيات',
    'grade_level': 'الصف الأول الثانوي',
    'semester': 1,
    'book_title': 'كتاب الرياضيات الرسمي - ترم أول',
    'storage_url': 'https://example.com/mock.pdf',
    'processing_status': 'pending'
  }).select().single();

  final bookId = bookResponse['id'];
  print('✅ Record created! Book ID: $bookId');

  print('2. Triggering process-curriculum-book Edge Function...');
  
  try {
    final response = await supabase.functions.invoke(
      'process-curriculum-book',
      body: {'book_id': bookId},
    );
    
    print('✅ Edge Function completed with status: ${response.status}');
    print('Response Data: ${response.data}');
  } catch (e) {
    print('❌ Edge Function failed: $e');
    print('Make sure your Edge Functions are deployed and OPENAI_API_KEY is set in Supabase Secrets.');
  }

  print('Done!');
  exit(0);
}
