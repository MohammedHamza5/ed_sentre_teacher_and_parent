import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization')!;
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const {
      pdfBase64,
      questionCount,
      language,
      difficulty,
      questionTypes
    } = await req.json();

    if (!pdfBase64 || !questionCount || !language || !difficulty || !questionTypes) {
      return new Response(JSON.stringify({ error: 'Missing required fields' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const geminiApiKey = Deno.env.get('GEMINI_API_KEY');
    if (!geminiApiKey) {
      throw new Error('GEMINI_API_KEY is not set');
    }

    const systemPrompt = `أنت نظام ذكاء اصطناعي متخصص في إعداد الاختبارات التعليمية لطلاب المرحلة الثانوية في مصر.

مهمتك:
- اقرأ المحتوى التعليمي في الملف المرفق بعمق.
- أنشئ اختباراً مكوناً من ${questionCount} سؤال باللغة ${language}.
- مستوى الصعوبة: ${difficulty}.
- أنواع الأسئلة المطلوبة: ${questionTypes.join(', ')}.
- وزّع الأسئلة بشكل متوازن على أجزاء المحتوى — لا تركّز على فقرة واحدة.
- لكل سؤال MCQ: أضف 4 خيارات، مع rationale لكل خيار يشرح لماذا هو صحيح أو خاطئ.
- لكل سؤال: أضف hint يساعد الطالب دون أن يكشف الإجابة مباشرة.
- لكل سؤال: أضف explanation شاملاً للإجابة الصحيحة.

قواعد صارمة:
- المخرج يجب أن يكون JSON فقط — لا نص، لا تعليقات، لا markdown.
- التزم بالـ JSON Schema المحدد بدقة تامة.
- لا تخترع معلومات غير موجودة في الملف.
- إذا كان المحتوى لا يكفي لعدد الأسئلة المطلوب، أنشئ ما يمكن وأضف "note" في جذر الـ JSON.`;

    const requestBody = {
      contents: [
        {
          parts: [
            { text: systemPrompt },
            {
              inline_data: {
                mime_type: "application/pdf",
                data: pdfBase64
              }
            }
          ]
        }
      ],
      generationConfig: {
        response_mime_type: "application/json",
        responseSchema: {
          type: "object",
          properties: {
            title: { type: "string" },
            estimated_time_minutes: { type: "integer" },
            total_marks: { type: "integer" },
            questions: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  type: { type: "string", description: "Must be exactly 'mcq' or 'true_false'" },
                  question: { type: "string", description: "The text of the question" },
                  options: {
                    type: "array",
                    items: { type: "string" },
                    description: "List of exactly 4 options for mcq. Or exactly 2 options for true_false (e.g., ['صح', 'خطأ'])"
                  },
                  correct_answer: { type: "integer", description: "Zero-based index of the correct option in the options array" },
                  explanation: { type: "string", description: "Detailed rationale of why the answer is correct" },
                  hint: { type: "string", description: "A subtle hint to guide the student" },
                  marks: { type: "integer", description: "Points assigned to this question" },
                  difficulty: { type: "string", description: "Difficulty level" }
                },
                required: ["type", "question", "options", "correct_answer", "explanation", "hint", "marks", "difficulty"]
              }
            }
          },
          required: ["title", "estimated_time_minutes", "total_marks", "questions"]
        },
        temperature: 0.4
      }
    };

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=${geminiApiKey}`;

    const geminiResponse = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(requestBody),
    });

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text();
      return new Response(JSON.stringify({ error: `Gemini API Error: ${errorText}` }), {
        status: geminiResponse.status,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const geminiData = await geminiResponse.json();
    const generatedText = geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!generatedText) {
       return new Response(JSON.stringify({ error: 'Empty response from Gemini' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    
    // Parse the JSON just to validate it's proper JSON before sending
    let parsedJson;
    try {
       parsedJson = JSON.parse(generatedText);
    } catch(e) {
       return new Response(JSON.stringify({ error: 'Gemini did not return valid JSON' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify(parsedJson), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
