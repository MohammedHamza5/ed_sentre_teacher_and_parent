import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.23.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface ChatMsg {
  id: string;
  role: string;
  type: string;
  content?: string;
  toolName?: string;
  toolArgs?: any;
  createdAt?: string;
}

// NOTE: Determines current academic semester based on calendar month.
// Sept–Jan = Semester 1, Feb–June = Semester 2. July–Aug defaults to Semester 2.
function getCurrentSemester(): number {
  const month = new Date().getMonth() + 1;
  return (month >= 9 || month === 1) ? 1 : 2;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { teacher_id, center_id, message, history = [], context = {} } = await req.json();

    const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY');
    const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY');
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
    const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!GEMINI_API_KEY) {
      throw new Error('GEMINI_API_KEY is missing from Supabase Edge Function environment secrets.');
    }

    const teacherName: string = context.teacher_name || 'الأستاذ';
    const subjectRaw: string = context.subject || '';
    const gradeLevels: string[] = context.grade_levels || [];
    const contextSemester: number = context.current_semester || getCurrentSemester();
    const curriculumAvailable: boolean = context.curriculum_available === true;
    const groups = context.groups || [];

    // ─────────────────────────────────────────────────────────────────
    // RAG: Semantic search in curriculum_chunks for relevant textbook content
    // NOTE: We use OpenAI for embeddings (1536 dims) to match how
    // process-curriculum-book stored them. Falls back gracefully if unavailable.
    // ─────────────────────────────────────────────────────────────────
    let curriculumContext = '';

    if (curriculumAvailable && OPENAI_API_KEY && SUPABASE_URL && SUPABASE_SERVICE_KEY && subjectRaw) {
      try {
        // Step 1: Generate query embedding
        const embRes = await fetch('https://api.openai.com/v1/embeddings', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${OPENAI_API_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ model: 'text-embedding-3-small', input: message.substring(0, 2000) }),
        });

        if (embRes.ok) {
          const embData = await embRes.json();
          const queryEmbedding: number[] = embData.data[0].embedding;
          const embeddingStr = `[${queryEmbedding.join(',')}]`;

          // Step 2: Semantic search via RPC
          const gradeFilter = gradeLevels.length > 0 ? gradeLevels[0] : null;
          const rpcBody: any = {
            query_embedding: embeddingStr,
            p_subject_name: subjectRaw,
            p_semester: contextSemester,
            p_limit: 4,
          };
          if (gradeFilter) rpcBody.p_grade_level = gradeFilter;

          const rpcRes = await fetch(`${SUPABASE_URL}/rest/v1/rpc/search_curriculum_chunks`, {
            method: 'POST',
            headers: {
              'apikey': SUPABASE_SERVICE_KEY,
              'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(rpcBody),
          });

          if (rpcRes.ok) {
            const chunks: any[] = await rpcRes.json();
            if (Array.isArray(chunks) && chunks.length > 0) {
              const formatted = chunks.map((c: any) => {
                const loc = [c.unit_title, c.lesson_title].filter(Boolean).join(' — ');
                return `📘 ${loc || 'محتوى الكتاب'}:\n${c.content}`;
              }).join('\n\n---\n\n');
              curriculumContext = formatted;
            }
          }
        }
      } catch (ragErr) {
        // NOTE: RAG failure is non-fatal — the AI still answers without curriculum context
        console.warn('RAG search failed (non-fatal):', ragErr);
      }
    }

    // ─────────────────────────────────────────────────────────────────
    // Build System Prompt
    // ─────────────────────────────────────────────────────────────────
    const curriculumSection = curriculumContext
      ? `\n\n═══ محتوى المنهج الرسمي ذو الصلة ═══\n${curriculumContext}\n═════════════════════════════════════\nاستخدم هذا المحتوى كمرجع أساسي. لا تخترع معلومات خارج هذا المنهج.`
      : '';

    const subjectDisplay = subjectRaw || 'المادة الدراسية';
    const semesterDisplay = `الترم ${contextSemester}`;
    const gradesDisplay = gradeLevels.length > 0 ? `(الصفوف: ${gradeLevels.join('، ')})` : '';

    const systemPrompt = `أنت المساعد الذكي الخبير للمعلم والسنتر التعليمي داخل منظومة (EdSentre AI Partner).
أنت الآن في محادثة مع المعلم: (${teacherName})، متخصص في: (${subjectDisplay}) ${gradesDisplay} — ${semesterDisplay}.
المجموعات التعليمية: ${JSON.stringify(groups, null, 2)}${curriculumSection}

مبادئك:
1. أنت شريك ذكي (AI Partner) تفهم المنهج والطلاب والمجموعات الحقيقية.
2. تخاطب المعلم بعربية فصحى مبسطة أو لهجة مصرية مهنية راقية.
3. إذا طلب المعلم امتحاناً بشكل عام غير محدد — ناقشه واستوضح الوحدة والصعوبة والمجموعة.
4. عند توليد الامتحان بمحددات كافية — استدعِ أداة \`generate_exam\` حصراً، ولا تسرد الأسئلة كنص.
5. الأسئلة من كتاب المنهج الرسمي أولاً إن كان متوفراً، وإلا من معرفتك العلمية الموثوقة.`;

    // Build Gemini contents array
    const geminiContents: Array<{ role: string; parts: Array<{ text?: string }> }> = [];

    for (const msg of (history as ChatMsg[])) {
      if (msg.type === 'toolCall' || msg.toolName) {
        geminiContents.push({
          role: 'model',
          parts: [{ text: `[تم استدعاء أداة ${msg.toolName || 'generate_exam'} بنجاح].` }],
        });
      } else if (msg.content && msg.content.trim().length > 0) {
        const role = (msg.role === 'assistant' || msg.role === 'model') ? 'model' : 'user';
        geminiContents.push({ role, parts: [{ text: msg.content }] });
      }
    }

    geminiContents.push({ role: 'user', parts: [{ text: message }] });

    const tools = [{
      functionDeclarations: [{
        name: 'generate_exam',
        description: 'إنشاء كارت امتحان تفاعلي شامل للمعلم للمراجعة والنشر.',
        parameters: {
          type: 'object',
          properties: {
            title: { type: 'string', description: 'عنوان الامتحان' },
            unit: { type: 'string', description: 'الوحدة أو الموضوع المستهدف' },
            question_count: { type: 'integer', description: 'عدد الأسئلة' },
            estimated_time_minutes: { type: 'integer', description: 'الوقت بالدقائق' },
            difficulty: { type: 'string', description: 'easy / medium / hard / mixed' },
            questions: {
              type: 'array',
              description: 'قائمة الأسئلة',
              items: {
                type: 'object',
                properties: {
                  text: { type: 'string', description: 'نص السؤال' },
                  type: { type: 'string', description: 'mcq أو true_false' },
                  options: { type: 'array', items: { type: 'string' }, description: 'الخيارات' },
                  correct_answer: { type: 'integer', description: 'فهرس الإجابة الصحيحة (0-3)' },
                  explanation: { type: 'string', description: 'تفسير الإجابة الصحيحة' },
                  marks: { type: 'integer', description: 'الدرجة المخصصة' },
                },
                required: ['text', 'type', 'options', 'correct_answer', 'explanation', 'marks'],
              },
            },
          },
          required: ['title', 'question_count', 'estimated_time_minutes', 'questions', 'difficulty'],
        },
      }],
    }];

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`;

    const res = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: systemPrompt }] },
        contents: geminiContents,
        tools,
        generationConfig: { temperature: 0.4 },
      }),
    });

    if (!res.ok) {
      const errData = await res.json().catch(() => ({}));
      console.error('Gemini API Error:', res.status, JSON.stringify(errData));
      throw new Error(`Gemini API Error: ${res.statusText} — ${JSON.stringify(errData)}`);
    }

    const aiData = await res.json();
    const candidate = aiData.candidates?.[0];
    if (!candidate) throw new Error('No response from Gemini API.');

    const messages: Array<any> = [];
    const now = new Date().toISOString();

    for (const part of (candidate.content?.parts || [])) {
      if (part.text && part.text.trim().length > 0) {
        messages.push({
          id: `msg_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
          role: 'assistant',
          type: 'text',
          content: part.text.trim(),
          createdAt: now,
        });
      }

      if (part.functionCall && part.functionCall.name === 'generate_exam') {
        const args: any = part.functionCall.args || {};
        const rawQuestions = Array.isArray(args.questions) ? args.questions : [];

        const processedQuestions = rawQuestions.map((q: any, idx: number) => ({
          id: q.id || `q_${Date.now()}_${idx}`,
          text: q.text || q.question || 'سؤال بدون نص',
          question: q.question || q.text || 'سؤال بدون نص',
          type: q.type || 'mcq',
          options: Array.isArray(q.options) ? q.options : ['أ', 'ب', 'ج', 'د'],
          correct_answer: typeof q.correct_answer === 'number' ? q.correct_answer : 0,
          explanation: q.explanation || 'تفسير الإجابة الصحيحة وفق المنهج الدراسي.',
          marks: typeof q.marks === 'number' ? q.marks : 2,
        }));

        const cleanArgs = {
          title: args.title || 'امتحان مقترح',
          unit: args.unit || 'مراجعة عامة',
          question_count: processedQuestions.length || args.question_count || 10,
          estimated_time_minutes: args.estimated_time_minutes || (processedQuestions.length * 2) || 20,
          difficulty: args.difficulty || 'medium',
          questions: processedQuestions,
        };

        if (messages.length === 0) {
          messages.push({
            id: `msg_intro_${Date.now()}`,
            role: 'assistant',
            type: 'text',
            content: `تم تجهيز امتحان (${cleanArgs.title}) بالمواصفات المطلوبة! اضغط على الكارت للانتقال لشاشة المراجعة والاعتماد:`,
            createdAt: now,
          });
        }

        messages.push({
          id: `tool_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
          role: 'assistant',
          type: 'toolCall',
          toolCallId: `call_${Date.now()}`,
          toolName: 'generate_exam',
          toolArgs: cleanArgs,
          createdAt: now,
        });
      }
    }

    if (messages.length === 0) {
      messages.push({
        id: `msg_${Date.now()}`,
        role: 'assistant',
        type: 'text',
        content: 'أنا هنا لمساعدتك يا أستاذي! كيف يمكنني دعمك اليوم في التحضير أو إعداد الامتحانات؟',
        createdAt: now,
      });
    }

    return new Response(JSON.stringify({ success: true, messages }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (err: any) {
    console.error('Edge Function ai-teacher-assistant Error:', err);
    return new Response(
      JSON.stringify({ success: false, error: err.message || 'Server Internal Error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
