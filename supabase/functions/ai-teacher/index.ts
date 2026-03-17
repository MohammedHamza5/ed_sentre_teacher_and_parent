import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// --- Gemini AI Helper ---
serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { task, content, params, model, file_path, difficulty } = await req.json();
    const finalDifficulty = difficulty || params?.difficulty;

    const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY');
    if (!GEMINI_API_KEY) {
      throw new Error('GEMINI_API_KEY is missing from Edge Function secrets.');
    }

    const baseSystemPrompt = `أنت مساعد ذكي مخصص لمعلم مصري. اسمك 'المساعد الذكي للمعلم'.
مهامك الرئيسية التفكير كمعلم خبير بأسلوب واضح ومهني وبلهجة عربية فصحى مع لمسة مصرية بسيطة إذا لزم الأمر في الشرح.
يجب أن تركز دائماً على إفادة الطالب ومساعدة المعلم في التحضير والتقييم وتحليل الأداء.`;

    let temperature = 0.7;
    let isJsonRequest = false;

    if (task === 'generate_exam' || task === 'generate_assignment' || task === 'analyze_performance') {
        isJsonRequest = true;
    }

    let finalPrompt = '';

    if (task === 'generate_exam') {
      temperature = 0.2;
      const qCount = params?.questionCount ?? 10;
      const exactDifficulty = finalDifficulty || 'medium';
      
      let diffText = 'متوسط';
      if(exactDifficulty === 'easy') diffText = 'سهل جداً ومباشر';
      else if(exactDifficulty === 'hard') diffText = 'صعب ويحتاج تفكير عميق (مستوى المتفوقين)';
      else if(exactDifficulty === 'mixed') diffText = 'متنوع (30% سهل، 50% متوسط، 20% صعب)';

      finalPrompt = `قم بإنشاء امتحان مكون من ${qCount} أسئلة من نوع (اختيار من متعدد وصح أو خطأ) بناءً على المحتوى التالي.
مستوى الصعوبة المطلوب: ${diffText}.

المحتوى:
${content}

يجب أن يكون الرد بتنسيق JSON حصراً كالتالي:
{
  "title": "عنوان المقترح للامتحان",
  "total_marks": ${qCount * 2},
  "estimated_time_minutes": ${qCount * 2},
  "questions": [
    {
      "type": "multiple_choice",
      "question": "نص السؤال",
      "options": ["خيار 1", "خيار 2", "خيار 3", "خيار 4"],
      "correct_answer": 0,
      "difficulty": "${exactDifficulty}",
      "marks": 2
    },
    {
      "type": "true_false",
      "question": "نص السؤال",
      "correct_answer": 0, // يجب أن تكون 0 للصح و 1 للخطأ
      "difficulty": "${exactDifficulty}",
      "marks": 2
    }
  ]
}
الرد يجب أن يكون JSON فقط بدون أي نصوص أو تعليقات خارجية.
`;
    } else if (task === 'chat') {
        const history = params?.history || [];
        for(let i=0; i<history.length; i++) {
           finalPrompt += `${history[i].role}: ${history[i].content}\n`;
        }
        finalPrompt += `user: ${content}`;
    } else if (task === 'auto_name_conversation') {
        finalPrompt = `لخص الرسالة التالية في عنوان قصير ومميز للمحادثة (3 إلى 5 كلمات كحد أقصى) بدون أي مسافات أو أسطر إضافية: "${content}"`;
    } else {
        finalPrompt = content;
    }

    console.log(`Calling Gemini with task: ${task}`);
    
    // Using gemini-1.5-flash-latest as it supports up to 1M tokens, perfect for 50 page PDFs
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=${GEMINI_API_KEY}`;

    const bodyVariables: any = {
      contents: [
        {
          role: 'user',
          parts: [{ text: finalPrompt }]
        }
      ],
      systemInstruction: {
        role: 'user',
        parts: [{ text: baseSystemPrompt }]
      },
      generationConfig: {
        temperature: temperature,
      }
    };

    if (isJsonRequest) {
      bodyVariables.generationConfig.responseMimeType = 'application/json';
    }

    const aiRes = await fetch(geminiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(bodyVariables)
    });

    if (!aiRes.ok) {
        const errObj = await aiRes.json().catch(() => ({}));
        console.error('Gemini Error Response:', aiRes.status, JSON.stringify(errObj));
        throw new Error(`Gemini Error: ${aiRes.statusText} ${JSON.stringify(errObj)}`);
    }

    const aiData = await aiRes.json();
    let textResult = '';
    
    if (aiData.candidates && aiData.candidates.length > 0 && aiData.candidates[0].content?.parts?.length > 0) {
      textResult = aiData.candidates[0].content.parts[0].text.trim();
    } else {
      console.error('Invalid Gemini Output:', JSON.stringify(aiData));
      throw new Error('Gemini returned an empty or invalid response structure.');
    }

    return new Response(JSON.stringify({ result: textResult, content: textResult }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (err: any) {
    console.error('Edge Function Error:', err);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
