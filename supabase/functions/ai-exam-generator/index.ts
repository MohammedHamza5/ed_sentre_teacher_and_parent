import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

// ═══════════════════════════════════════════════════════════════════════════
// EdSentre AI Exam Generator — Edge Function v2
// الحل: إرسال PDF كـ inline_data مباشرة لـ Gemini 1.5 Flash
// يقرأ الصور + النصوص + الجداول + العربية — بدون استخراج نص
// الحد: 20MB للملف | مجاني ضمن حد Gemini المجاني
// ═══════════════════════════════════════════════════════════════════════════

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const GEMINI_URL =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

// ─── Types ─────────────────────────────────────────────────────────────────

interface RequestBody {
  task: 'generate_exam' | 'generate_from_text' | 'chat' | 'auto_name';
  pdfBase64?: string;
  content?: string;
  params?: {
    questionCount?: number;
    difficulty?: string;
    examType?: string;
    language?: string;
    history?: Array<{ role: string; content: string }>;
  };
  difficulty?: string;
}

// ─── System prompt ─────────────────────────────────────────────────────────

const SYSTEM = `أنت خبير تربوي متخصص في إعداد الاختبارات للمرحلة الثانوية في مصر.
مهمتك: تحليل المحتوى التعليمي المرفق وإنشاء أسئلة عالية الجودة تقيس الفهم العميق.
القواعد الصارمة:
- لا تخترع معلومات غير موجودة في المحتوى
- وزّع الأسئلة على جميع أجزاء المحتوى — لا تركّز على فقرة واحدة
- اكتب بعربية فصحى واضحة
- كل سؤال يجب أن يحتوي على explanation وهint مفيدين للطالب`;

function difficultyLabel(d: string): string {
  return ({ easy: 'سهل — أسئلة مباشرة', medium: 'متوسط — تقيس الفهم والتطبيق', hard: 'صعب — تحليل عميق', mixed: 'متنوع (30% سهل، 50% متوسط، 20% صعب)' })[d] ?? 'متوسط';
}

function buildPrompt(params: RequestBody['params'], difficulty: string): string {
  const count = params?.questionCount ?? 10;
  const examType = params?.examType ?? 'exam';
  const typeLabel = ({ exam: 'امتحان شامل', quiz: 'كويز سريع', assignment: 'واجب منزلي' })[examType] ?? 'امتحان';

  return `${SYSTEM}

المطلوب: إنشاء ${typeLabel} — ${count} سؤال — مستوى: ${difficultyLabel(difficulty)}
اللغة: ${params?.language === 'en' ? 'English' : 'عربية فصحى'}

الرد يجب أن يكون JSON فقط بهذا الشكل الدقيق:
{
  "title": "عنوان مناسب",
  "subject": "اسم المادة",
  "difficulty": "${difficulty}",
  "total_marks": ${count * 2},
  "estimated_time_minutes": ${count * 2},
  "questions": [
    {
      "id": "q_1",
      "type": "mcq",
      "text": "نص السؤال",
      "options": ["أ", "ب", "ج", "د"],
      "correct_answer": 0,
      "explanation": "الإجابة صحيحة لأن ... الخيارات الأخرى خاطئة لأن ...",
      "hint": "تذكر أن ... / فكر في ...",
      "difficulty": "medium",
      "marks": 2
    },
    {
      "id": "q_2",
      "type": "true_false",
      "text": "عبارة للحكم عليها",
      "options": ["صح", "خطأ"],
      "correct_answer": 1,
      "explanation": "هذه العبارة خاطئة لأن ...",
      "hint": "ما الشرط الأساسي لـ ...؟",
      "difficulty": "easy",
      "marks": 2
    }
  ]
}`;
}

// ─── Gemini API call (JSON mode) ────────────────────────────────────────────

async function callGemini(parts: unknown[], temperature = 0.2): Promise<string> {
  const key = Deno.env.get('GEMINI_API_KEY');
  if (!key) throw new Error('GEMINI_API_KEY غير موجود في Supabase secrets.');

  const res = await fetch(`${GEMINI_URL}?key=${key}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ role: 'user', parts }],
      generationConfig: {
        temperature,
        maxOutputTokens: 8192,
        responseMimeType: 'application/json',
      },
    }),
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(`Gemini API ${res.status}: ${JSON.stringify(err)}`);
  }

  const data = await res.json();
  const text = data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? '';
  if (!text) throw new Error('Gemini أرجع رداً فارغاً — حاول مرة أخرى.');
  return text;
}

// ─── Gemini call (text mode, for chat) ─────────────────────────────────────

async function callGeminiText(parts: unknown[]): Promise<string> {
  const key = Deno.env.get('GEMINI_API_KEY');
  if (!key) throw new Error('GEMINI_API_KEY غير موجود.');

  const res = await fetch(`${GEMINI_URL}?key=${key}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ role: 'user', parts }],
      generationConfig: { temperature: 0.7, maxOutputTokens: 2048 },
    }),
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(`Gemini ${res.status}: ${JSON.stringify(err)}`);
  }

  const data = await res.json();
  return data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? '';
}

// ─── Parse + normalize exam JSON ───────────────────────────────────────────

function parseAndNormalize(raw: string, difficulty: string): Record<string, unknown> {
  let s = raw.trim();
  if (s.startsWith('```json')) s = s.slice(7);
  else if (s.startsWith('```')) s = s.slice(3);
  if (s.endsWith('```')) s = s.slice(0, -3);
  s = s.trim();

  const parsed = JSON.parse(s) as Record<string, unknown>;
  const rawQ = parsed['questions'];

  if (!Array.isArray(rawQ) || rawQ.length === 0) {
    throw new Error('AI لم يُنشئ أي أسئلة. الملف ربما فارغ أو محتواه غير تعليمي.');
  }

  const questions = rawQ
    .map((q: unknown, i: number) => {
      if (typeof q !== 'object' || q === null) return null;
      const qo = q as Record<string, unknown>;

      const rawOpts = qo['options'];
      const opts = Array.isArray(rawOpts) ? rawOpts.map(String) : ['صح', 'خطأ'];

      const rawCA = qo['correct_answer'];
      const correct =
        typeof rawCA === 'number' ? rawCA : parseInt(String(rawCA ?? '0'), 10) || 0;

      return {
        id:           String(qo['id'] ?? `q_${i + 1}`),
        type:         String(qo['type'] ?? 'mcq'),
        text:         String(qo['text'] ?? qo['question'] ?? ''),
        options:      opts,
        correct_answer: correct,
        explanation:  String(qo['explanation'] ?? 'راجع المحتوى للتعرف على الإجابة الصحيحة.'),
        hint:         String(qo['hint'] ?? 'فكر في المفاهيم الأساسية التي تعلمتها.'),
        difficulty:   String(qo['difficulty'] ?? difficulty),
        marks:        Number(qo['marks'] ?? 2),
      };
    })
    .filter(Boolean);

  return {
    title:                    String(parsed['title'] ?? 'امتحان بالذكاء الاصطناعي'),
    subject:                  String(parsed['subject'] ?? ''),
    difficulty,
    total_marks:              Number(parsed['total_marks'] ?? questions.length * 2),
    estimated_time_minutes:   Number(parsed['estimated_time_minutes'] ?? questions.length * 2),
    questions,
  };
}

// ─── Main handler ───────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });

  try {
    const body        = await req.json() as RequestBody;
    const { task, pdfBase64, content, params } = body;
    const difficulty  = body.difficulty ?? params?.difficulty ?? 'medium';
    let result        = '';

    // ══ TASK 1: generate_exam من PDF (inline_data) ══════════════════════════
    if (task === 'generate_exam' && pdfBase64) {

      if (pdfBase64.length < 200) throw new Error('بيانات الـ PDF غير صالحة أو فارغة.');

      const approxMB = (pdfBase64.length * 0.75) / (1024 * 1024);
      if (approxMB > 19.5) {
        throw new Error(
          `حجم الملف كبير جداً (${approxMB.toFixed(1)} MB). ` +
          `الحد الأقصى 19.5 MB. قسّم الملف أو استخدم فصلاً واحداً.`
        );
      }

      const prompt = buildPrompt(params, difficulty);

      // ← الجوهر: part 1 = الملف، part 2 = الأوامر
      const parts = [
        {
          inline_data: {
            mime_type: 'application/pdf',
            data: pdfBase64,          // base64 string — لا encoding إضافي
          },
        },
        { text: prompt },
      ];

      const raw    = await callGemini(parts, 0.2);
      const exam   = parseAndNormalize(raw, difficulty);
      result       = JSON.stringify(exam);
    }

    // ══ TASK 2: generate_from_text أو generate_exam بدون PDF ════════════════
    else if (task === 'generate_exam' || task === 'generate_from_text') {
      if (!content || content.trim().length < 80) {
        throw new Error('المحتوى النصي قصير جداً (أقل من 80 حرف).');
      }

      const prompt = buildPrompt(params, difficulty);
      const combinedText = `${prompt}\n\nالمحتوى التعليمي:\n"""\n${content.slice(0, 14000)}\n"""`;
      const raw  = await callGemini([{ text: combinedText }], 0.2);
      const exam = parseAndNormalize(raw, difficulty);
      result     = JSON.stringify(exam);
    }

    // ══ TASK 3: chat ════════════════════════════════════════════════════════
    else if (task === 'chat') {
      const history = params?.history ?? [];
      let prompt = `${SYSTEM}\n\n`;
      for (const m of history.slice(-10)) {
        prompt += `${m.role === 'user' ? 'المستخدم' : 'المساعد'}: ${m.content}\n`;
      }
      prompt += `المستخدم: ${content ?? ''}`;
      result = await callGeminiText([{ text: prompt }]);
    }

    // ══ TASK 4: auto_name ════════════════════════════════════════════════════
    else if (task === 'auto_name') {
      const raw = await callGeminiText([{
        text: `لخّص هذه الرسالة في عنوان قصير (3-5 كلمات) بدون علامات تنصيص:\n"${content}"`,
      }]);
      result = raw.replace(/["'`*]/g, '').trim();
    }

    else {
      throw new Error(`task غير معروف: "${task}"`);
    }

    return new Response(
      JSON.stringify({ result, content: result, success: true }),
      { headers: { ...CORS, 'Content-Type': 'application/json' } },
    );

  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error('[ai-exam-generator] Error:', msg);
    return new Response(
      JSON.stringify({ error: msg, success: false }),
      { status: 500, headers: { ...CORS, 'Content-Type': 'application/json' } },
    );
  }
});
