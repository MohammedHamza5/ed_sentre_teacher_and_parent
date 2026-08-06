import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// NOTE: Splits text into overlapping chunks for better semantic coverage.
// 500-word chunks with 80-word overlap reduces context loss at boundaries.
function chunkText(text: string, chunkSize = 500, overlap = 80): string[] {
  const words = text.split(/\s+/).filter(w => w.length > 0);
  const chunks: string[] = [];
  let i = 0;
  while (i < words.length) {
    const chunk = words.slice(i, i + chunkSize).join(' ');
    if (chunk.trim().length > 50) {
      chunks.push(chunk);
    }
    i += chunkSize - overlap;
  }
  return chunks;
}

// NOTE: Generates an OpenAI embedding for a text chunk.
// Using text-embedding-3-small (1536 dims) — best cost/quality ratio for Arabic.
async function generateEmbedding(text: string, openAiKey: string): Promise<number[]> {
  const response = await fetch('https://api.openai.com/v1/embeddings', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${openAiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'text-embedding-3-small',
      input: text.substring(0, 8000), // API limit guard
    }),
  });

  if (!response.ok) {
    const err = await response.json().catch(() => ({}));
    throw new Error(`OpenAI Embedding Error: ${JSON.stringify(err)}`);
  }

  const data = await response.json();
  return data.data[0].embedding as number[];
}

// NOTE: Uses GPT-4o mini to extract book structure (units + lessons) from the first
// 8000 characters which typically contains the table of contents.
async function extractBookStructure(
  bookText: string,
  bookTitle: string,
  subjectName: string,
  openAiKey: string,
): Promise<Array<{ unit_number: number; unit_title: string; lessons: Array<{ lesson_number: number; lesson_title: string; objectives: string[] }> }>> {
  const prompt = `أنت خبير تربوي. المهمة: استخرج هيكل الكتاب الدراسي التالي بدقة.

الكتاب: "${bookTitle}"
المادة: "${subjectName}"

النص (بداية الكتاب):
${bookText.substring(0, 8000)}

المطلوب: JSON فقط بالشكل التالي — لا تضف أي نص خارج الـ JSON:
{
  "units": [
    {
      "unit_number": 1,
      "unit_title": "اسم الوحدة",
      "lessons": [
        {
          "lesson_number": 1,
          "lesson_title": "اسم الدرس",
          "objectives": ["هدف 1", "هدف 2"]
        }
      ]
    }
  ]
}

إذا لم تجد فهرساً واضحاً، استنتج الهيكل من العناوين الرئيسية والفرعية.`;

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${openAiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      response_format: { type: 'json_object' },
      temperature: 0.2,
    }),
  });

  if (!response.ok) {
    const err = await response.json().catch(() => ({}));
    throw new Error(`OpenAI Structure Extraction Error: ${JSON.stringify(err)}`);
  }

  const data = await response.json();
  const content = data.choices[0].message.content;
  const parsed = JSON.parse(content);
  return parsed.units || [];
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const openAiKey = Deno.env.get('OPENAI_API_KEY');

  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  try {
    const { book_id } = await req.json();
    if (!book_id) {
      return new Response(JSON.stringify({ success: false, error: 'book_id is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 1. Fetch book record
    const { data: book, error: bookErr } = await supabase
      .from('curriculum_books')
      .select('*')
      .eq('id', book_id)
      .single();

    if (bookErr || !book) {
      throw new Error(`Book not found: ${bookErr?.message}`);
    }

    // 2. Mark as processing
    await supabase.from('curriculum_books').update({ processing_status: 'processing' }).eq('id', book_id);

    // 3. Download PDF from storage
    const storagePath = book.storage_url.split('/object/public/curriculum-books/')[1];
    if (!storagePath) throw new Error('Cannot parse storage path from storage_url');

    const { data: fileData, error: fileErr } = await supabase
      .storage
      .from('curriculum-books')
      .download(storagePath);

    if (fileErr || !fileData) throw new Error(`Failed to download book: ${fileErr?.message}`);

    // 4. Extract text from PDF (plain text fallback — real PDF parsing needs pdf-parse)
    // NOTE: For production, integrate a PDF parsing service or use Supabase's pg_net
    // to call an external PDF→text API. For now we use the raw content.
    const arrayBuffer = await fileData.arrayBuffer();
    const uint8Array = new Uint8Array(arrayBuffer);

    // Basic text extraction: strip PDF binary, keep readable ASCII/Unicode chars
    let rawText = new TextDecoder('utf-8', { fatal: false }).decode(uint8Array);
    // Remove binary noise, keep Arabic and Latin text
    rawText = rawText.replace(/[^\u0600-\u06FF\u0020-\u007E\n\r\t]/g, ' ').replace(/\s{3,}/g, '\n').trim();

    if (rawText.length < 100) {
      throw new Error('Could not extract readable text from PDF. Consider a pre-processing pipeline.');
    }

    // 5. Extract book structure using AI
    const units = await extractBookStructure(rawText, book.book_title, book.subject_name, openAiKey!);

    // 6. Save structure to curriculum_structure
    let orderNum = 0;
    const structureRows: any[] = [];

    for (const unit of units) {
      if (unit.lessons && unit.lessons.length > 0) {
        for (const lesson of unit.lessons) {
          structureRows.push({
            book_id: book_id,
            subject_name: book.subject_name,
            grade_level: book.grade_level,
            semester: book.semester,
            unit_number: unit.unit_number,
            unit_title: unit.unit_title,
            lesson_number: lesson.lesson_number,
            lesson_title: lesson.lesson_title,
            lesson_objectives: lesson.objectives || [],
            duration_mins: 45,
            order_num: orderNum++,
          });
        }
      } else {
        // Unit without lessons
        structureRows.push({
          book_id: book_id,
          subject_name: book.subject_name,
          grade_level: book.grade_level,
          semester: book.semester,
          unit_number: unit.unit_number,
          unit_title: unit.unit_title,
          lesson_number: null,
          lesson_title: null,
          lesson_objectives: [],
          duration_mins: 45,
          order_num: orderNum++,
        });
      }
    }

    if (structureRows.length > 0) {
      const { error: structErr } = await supabase.from('curriculum_structure').insert(structureRows);
      if (structErr) throw new Error(`Failed to insert curriculum_structure: ${structErr.message}`);
    }

    // 7. Chunk the text and generate embeddings
    const chunks = chunkText(rawText);
    let chunkIndex = 0;

    for (const chunk of chunks) {
      let embedding: number[] | null = null;

      if (openAiKey) {
        try {
          embedding = await generateEmbedding(chunk, openAiKey);
        } catch (embErr) {
          console.warn(`Embedding failed for chunk ${chunkIndex}:`, embErr);
        }
      }

      await supabase.from('curriculum_chunks').insert({
        book_id: book_id,
        subject_name: book.subject_name,
        grade_level: book.grade_level,
        semester: book.semester,
        unit_title: units[0]?.unit_title ?? null,
        lesson_title: null,
        content: chunk,
        embedding: embedding,
        chunk_index: chunkIndex++,
      });
    }

    // 8. Update book status to done
    await supabase.from('curriculum_books').update({
      processing_status: 'done',
      processing_error: null,
    }).eq('id', book_id);

    return new Response(
      JSON.stringify({
        success: true,
        units_count: units.length,
        lessons_count: structureRows.filter(r => r.lesson_title != null).length,
        chunks_count: chunks.length,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );

  } catch (err: any) {
    console.error('process-curriculum-book error:', err);

    // Mark book as failed so the admin knows
    try {
      const body = await req.json().catch(() => ({}));
      if ((body as any).book_id) {
        const sbAdmin = createClient(supabaseUrl, supabaseServiceKey);
        await sbAdmin.from('curriculum_books').update({
          processing_status: 'failed',
          processing_error: err.message,
        }).eq('id', (body as any).book_id);
      }
    } catch (_) {}

    return new Response(
      JSON.stringify({ success: false, error: err.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
