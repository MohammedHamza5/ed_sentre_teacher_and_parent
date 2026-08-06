import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

// ═══════════════════════════════════════════════════════════════════════════
// EdSentre AI Exam Generator — Edge Function v7
// ─ Model: Gemini 2.5 Flash
// ─ Retry + Timeout 90s + 16384 tokens
// ═══════════════════════════════════════════════════════════════════════════

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// NOTE: تم الترقية من gemini-2.0-flash إلى gemini-2.5-flash
// أذكى + نفس الحد المجاني (1500 طلب/يوم)
const GEMINI_MODEL = 'gemini-3.5-flash';
const GEMINI_URL =
  `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

const MAX_RETRIES = 1; // إعادة محاولة مرة واحدة عند الفشل
const MAX_OUTPUT_TOKENS = 16384; // ضعف السابق — يدعم أسئلة أكثر

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

// ─── System prompt (محسّن) ──────────────────────────────────────────────────

const SYSTEM = `أنت خبير تربوي متخصص في إعداد الاختبارات التعليمية.
مهمتك: تحليل المحتوى التعليمي المرفق وإنشاء أسئلة عالية الجودة تقيس الفهم العميق.

القواعد الصارمة:
1. لا تخترع معلومات غير موجودة في المحتوى — كل سؤال مبني على ما في الملف فقط
2. وزّع الأسئلة على جميع أجزاء المحتوى بالتساوي — لا تركّز على جزء واحد
3. اكتب بعربية فصحى واضحة وسليمة نحوياً
4. كل سؤال يجب أن يحتوي على explanation (شرح كامل للإجابة) و hint (تلميح مساعد للطالب)
5. تنوّع في أنواع الأسئلة: اختيار من متعدد (mcq)، صح وخطأ (true_false)
6. الأسئلة يجب أن تكون واضحة ولا تحتمل أكثر من إجابة صحيحة
7. correct_answer هو رقم index الإجابة الصحيحة (يبدأ من 0)
8. الخيارات يجب أن تكون متقاربة في الطول ومنطقية — لا تجعل الإجابة الصحيحة واضحة`;

function difficultyLabel(d: string): string {
  const labels: Record<string, string> = {
    easy: 'سهل — أسئلة مباشرة تقيس الحفظ والتذكر',
    medium: 'متوسط — أسئلة تقيس الفهم والتطبيق',
    hard: 'صعب — أسئلة تحليلية وتقييمية تحتاج تفكير عميق',
    mixed: 'متنوع (30% سهل، 50% متوسط، 20% صعب)',
  };
  return labels[d] ?? labels['medium'];
}

function buildPrompt(params: RequestBody['params'], difficulty: string): string {
  const count = params?.questionCount ?? 10;
  const examType = params?.examType ?? 'exam';
  const typeLabels: Record<string, string> = {
    exam: 'امتحان شامل',
    quiz: 'كويز سريع',
    assignment: 'واجب منزلي',
  };
  const typeLabel = typeLabels[examType] ?? 'امتحان';

  // NOTE: توزيع أنواع الأسئلة بحسب العدد المطلوب
  const mcqCount = Math.ceil(count * 0.7); // 70% MCQ
  const tfCount = count - mcqCount;        // 30% True/False

  return `${SYSTEM}

المطلوب: إنشاء ${typeLabel} مكون من ${count} سؤال
- ${mcqCount} سؤال اختيار من متعدد (mcq) بـ 4 خيارات
- ${tfCount} سؤال صح وخطأ (true_false) بخيارين ["صح", "خطأ"]
مستوى الصعوبة: ${difficultyLabel(difficulty)}
اللغة: ${params?.language === 'en' ? 'English' : 'عربية فصحى'}

الرد يجب أن يكون JSON فقط — بدون أي نص إضافي — بهذا الشكل الدقيق:
{
  "title": "عنوان مناسب يصف المحتوى",
  "subject": "اسم المادة",
  "difficulty": "${difficulty}",
  "total_marks": ${count * 2},
  "estimated_time_minutes": ${Math.max(count * 2, 10)},
  "questions": [
    {
      "id": "q_1",
      "type": "mcq",
      "text": "نص السؤال الواضح والكامل",
      "options": ["الخيار أ", "الخيار ب", "الخيار ج", "الخيار د"],
      "correct_answer": 0,
      "explanation": "الإجابة الصحيحة هي (أ) لأن ... والخيارات الأخرى خاطئة لأن ...",
      "hint": "تلميح: فكر في ... / تذكّر أن ...",
      "difficulty": "medium",
      "marks": 2
    },
    {
      "id": "q_2",
      "type": "true_false",
      "text": "عبارة واضحة للحكم عليها بصح أو خطأ",
      "options": ["صح", "خطأ"],
      "correct_answer": 1,
      "explanation": "هذه العبارة خاطئة لأن ... والصواب هو ...",
      "hint": "فكر في الشرط الأساسي لـ ...",
      "difficulty": "easy",
      "marks": 2
    }
  ]
}

تنبيه: correct_answer هو رقم index (يبدأ من 0). لسؤال MCQ: 0=أ، 1=ب، 2=ج، 3=د. لسؤال true_false: 0=صح، 1=خطأ.`;
}

// ─── Gemini API call with retry ─────────────────────────────────────────────

async function callGeminiWithRetry(
  parts: unknown[],
  temperature = 0.2,
  retries = MAX_RETRIES,
): Promise<string> {
  const key = Deno.env.get('GEMINI_API_KEY');
  if (!key) throw new Error('GEMINI_API_KEY غير موجود في Supabase secrets.');

  let lastError: Error | null = null;

  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      if (attempt > 0) {
        // NOTE: انتظار قبل إعادة المحاولة — 3 ثوانٍ
        console.log(`[ai-exam-generator] Retry attempt ${attempt}...`);
        await new Promise((r) => setTimeout(r, 3000));
      }

      const controller = new AbortController();
      // NOTE: timeout 90 ثانية — Gemini 2.0 Flash أسرع من 1.5
      const timeoutId = setTimeout(() => controller.abort(), 90_000);

      const res = await fetch(`${GEMINI_URL}?key=${key}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: controller.signal,
        body: JSON.stringify({
          contents: [{ role: 'user', parts }],
          generationConfig: {
            temperature,
            maxOutputTokens: MAX_OUTPUT_TOKENS,
            responseMimeType: 'application/json',
          },
        }),
      });

      clearTimeout(timeoutId);

      if (!res.ok) {
        const errBody = await res.json().catch(() => ({}));
        const statusCode = res.status;
        const errMsg = errBody?.error?.message ?? JSON.stringify(errBody);
        console.error(`[ai-exam-generator] Gemini ${statusCode}: ${errMsg}`);

        if (statusCode === 429) {
          throw new Error(
            'تم تجاوز الحد اليومي المجاني لـ Gemini. انتظر قليلاً ثم حاول مرة أخرى.',
          );
        }

        // NOTE: نمرر رسالة الخطأ الفعلية من Gemini
        throw new Error(`خطأ Gemini (${statusCode}): ${errMsg}`);
      }

      const data = await res.json();

      // التحقق من safety block
      const candidate = data?.candidates?.[0];
      if (candidate?.finishReason === 'SAFETY') {
        throw new Error(
          'تم رفض المحتوى بسبب سياسات الأمان. تأكد أن الملف تعليمي.',
        );
      }

      const text = candidate?.content?.parts?.[0]?.text?.trim() ?? '';
      if (!text) {
        throw new Error('Gemini أرجع رداً فارغاً — سيتم إعادة المحاولة.');
      }

      return text;
    } catch (err) {
      lastError = err instanceof Error ? err : new Error(String(err));

      // أخطاء لا يُعاد المحاولة عليها
      const noRetry = ['GEMINI_API_KEY', '429', 'الحد اليومي', 'سياسات الأمان'];
      if (noRetry.some((s) => lastError!.message.includes(s))) {
        throw lastError;
      }

      // إذا هذه آخر محاولة، ارمِ الخطأ
      if (attempt === retries) break;
    }
  }

  throw lastError ?? new Error('فشل الاتصال بـ Gemini بعد عدة محاولات.');
}

// ─── Gemini call for text (chat, auto_name) ─────────────────────────────────

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

function parseAndNormalize(
  raw: string,
  difficulty: string,
): Record<string, unknown> {
  let s = raw.trim();
  if (s.startsWith('```json')) s = s.slice(7);
  else if (s.startsWith('```')) s = s.slice(3);
  if (s.endsWith('```')) s = s.slice(0, -3);
  s = s.trim();

  let parsed: Record<string, unknown>;
  try {
    parsed = JSON.parse(s) as Record<string, unknown>;
  } catch {
    // NOTE: محاولة استخراج JSON من نص مختلط
    const jsonMatch = s.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      parsed = JSON.parse(jsonMatch[0]) as Record<string, unknown>;
    } else {
      throw new Error('فشل في تحليل رد AI. الرد ليس JSON صحيح.');
    }
  }

  const rawQ = parsed['questions'];
  if (!Array.isArray(rawQ) || rawQ.length === 0) {
    throw new Error(
      'AI لم يُنشئ أي أسئلة. تأكد أن الملف يحتوي على محتوى تعليمي كافٍ.',
    );
  }

  const questions = rawQ
    .map((q: unknown, i: number) => {
      if (typeof q !== 'object' || q === null) return null;
      const qo = q as Record<string, unknown>;

      const rawOpts = qo['options'];
      const opts = Array.isArray(rawOpts)
        ? rawOpts.map(String)
        : ['صح', 'خطأ'];

      const rawCA = qo['correct_answer'];
      let correct: number;
      if (typeof rawCA === 'number') {
        correct = rawCA;
      } else {
        correct = parseInt(String(rawCA ?? '0'), 10) || 0;
      }

      // حماية: index لا يتجاوز عدد الخيارات
      if (correct < 0 || correct >= opts.length) correct = 0;

      const type = String(qo['type'] ?? 'mcq').toLowerCase();

      return {
        id: String(qo['id'] ?? `q_${i + 1}`),
        type:
          type.includes('true') || type.includes('false')
            ? 'true_false'
            : 'mcq',
        text: String(qo['text'] ?? qo['question'] ?? ''),
        options: opts,
        correct_answer: correct,
        explanation: String(
          qo['explanation'] ?? 'راجع المحتوى للتعرف على الإجابة الصحيحة.',
        ),
        hint: String(
          qo['hint'] ?? 'فكر في المفاهيم الأساسية التي تعلمتها.',
        ),
        difficulty: String(qo['difficulty'] ?? difficulty),
        marks: Number(qo['marks'] ?? 2),
      };
    })
    .filter(Boolean);

  if (questions.length === 0) {
    throw new Error('فشل في معالجة الأسئلة. حاول مرة أخرى.');
  }

  return {
    title: String(parsed['title'] ?? 'امتحان بالذكاء الاصطناعي'),
    subject: String(parsed['subject'] ?? ''),
    difficulty,
    total_marks: Number(parsed['total_marks'] ?? questions.length * 2),
    estimated_time_minutes: Number(
      parsed['estimated_time_minutes'] ?? questions.length * 2,
    ),
    questions,
  };
}

// ─── Main handler ───────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });

  try {
    const body = (await req.json()) as RequestBody;
    const { task, pdfBase64, content, params } = body;
    const difficulty = body.difficulty ?? params?.difficulty ?? 'medium';
    let result = '';

    console.log(`[ai-exam-generator] Task: ${task}, Model: ${GEMINI_MODEL}`);

    // ══ TASK 1: generate_exam من PDF (inline_data) ══════════════════════════
    if (task === 'generate_exam' && pdfBase64) {
      if (pdfBase64.length < 200) {
        throw new Error('بيانات الـ PDF غير صالحة أو فارغة.');
      }

      const approxMB = (pdfBase64.length * 0.75) / (1024 * 1024);
      if (approxMB > 19.5) {
        throw new Error(
          `حجم الملف كبير جداً (${approxMB.toFixed(1)} MB). ` +
            `الحد الأقصى 19.5 MB. قسّم الملف أو استخدم فصلاً واحداً.`,
        );
      }

      console.log(
        `[ai-exam-generator] PDF size: ~${approxMB.toFixed(1)} MB, ` +
          `Questions: ${params?.questionCount ?? 10}`,
      );

      const prompt = buildPrompt(params, difficulty);
      const parts = [
        {
          inline_data: {
            mime_type: 'application/pdf',
            data: pdfBase64,
          },
        },
        { text: prompt },
      ];

      const raw = await callGeminiWithRetry(parts, 0.2);
      const exam = parseAndNormalize(raw, difficulty);
      result = JSON.stringify(exam);
    }

    // ══ TASK 2: generate_from_text أو generate_exam بدون PDF ════════════════
    else if (task === 'generate_exam' || task === 'generate_from_text') {
      if (!content || content.trim().length < 80) {
        throw new Error('المحتوى النصي قصير جداً (أقل من 80 حرف).');
      }

      const prompt = buildPrompt(params, difficulty);
      // NOTE: حد 30,000 حرف للنص — أكثر من ذلك يبطئ المعالجة
      const combinedText = `${prompt}\n\nالمحتوى التعليمي:\n"""\n${content.slice(0, 30000)}\n"""`;
      const raw = await callGeminiWithRetry([{ text: combinedText }], 0.2);
      const exam = parseAndNormalize(raw, difficulty);
      result = JSON.stringify(exam);
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
      const raw = await callGeminiText([
        {
          text: `لخّص هذه الرسالة في عنوان قصير (3-5 كلمات) بدون علامات تنصيص:\n"${content}"`,
        },
      ]);
      result = raw.replace(/["'`*]/g, '').trim();
    } else {
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
      {
        status: 500,
        headers: { ...CORS, 'Content-Type': 'application/json' },
      },
    );
  }
});
