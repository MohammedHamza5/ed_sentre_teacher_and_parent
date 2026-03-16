import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// --- Open AI Helper ---
serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { task, content, params, model, file_path, difficulty } = await req.json();
    const finalDifficulty = difficulty || params?.difficulty;

    const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY');
    if (!OPENAI_API_KEY) {
      throw new Error('OPENAI_API_KEY is missing from Edge Function secrets.');
    }

    const messages: any[] = [];
    const activeModel = 'gpt-4o-mini';

    const baseSystemPrompt = `أنت مساعد ذكي مخصص لمعلم مصري. اسمك 'المساعد الذكي للمعلم'.
مهامك الرئيسية التفكير كمعلم خبير بأسلوب واضح ومهني وبلهجة عربية فصحى مع لمسة مصرية بسيطة إذا لزم الأمر في الشرح.
يجب أن تركز دائماً على إفادة الطالب ومساعدة المعلم في التحضير والتقييم وتحليل الأداء.`;
    messages.push({ role: 'system', content: baseSystemPrompt });

    let temperature = 0.7;
    let isJsonRequest = false;

    if (task === 'generate_exam' || task === 'generate_assignment' || task === 'analyze_performance') {
        isJsonRequest = true;
    }

    if (task === 'generate_exam') {
      temperature = 0.2;
      const qCount = params?.questionCount ?? 10;
      const exactDifficulty = finalDifficulty || 'medium';
      
      let diffText = 'متوسط';
      if(exactDifficulty === 'easy') diffText = 'سهل جداً ومباشر';
      else if(exactDifficulty === 'hard') diffText = 'صعب ويحتاج تفكير عميق (مستوى المتفوقين)';
      else if(exactDifficulty === 'mixed') diffText = 'متنوع (30% سهل، 50% متوسط، 20% صعب)';

      const examPrompt = `قم بإنشاء امتحان مكون من ${qCount} أسئلة من نوع (اختيار من متعدد وصح أو خطأ) بناءً على المحتوى التالي.
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
      "correct_answer": 0,
      "difficulty": "${exactDifficulty}",
      "marks": 2
    }
  ]
}
الرد يجب أن يكون JSON فقط بدون أي نصوص أو تعليقات خارجية.
`;
      messages.push({ role: 'user', content: examPrompt });
    } else if (task === 'chat') {
        const history = params?.history || [];
        for(let i=0; i<history.length; i++) {
            messages.push({role: history[i].role, content: history[i].content});
        }
        messages.push({ role: 'user', content: content });
    } else if (task === 'auto_name_conversation') {
        messages.push({
            role: 'user',
            content: `لخص الرسالة التالية في عنوان قصير ومميز للمحادثة (3 إلى 5 كلمات كحد أقصى) بدون أي مسافات أو أسطر إضافية: "${content}"`
        });
    } else {
        messages.push({ role: 'user', content: content });
    }

    console.log(`Calling OpenAI with model: ${activeModel}, task: ${task}`);
    
    // Note: OpenAI API 
    const openAIUrl = 'https://api.openai.com/v1/chat/completions';

    const aiRes = await fetch(openAIUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: activeModel,
        messages: messages,
        temperature: temperature,
        response_format: isJsonRequest ? { type: 'json_object' } : undefined,
      })
    });

    if (!aiRes.ok) {
        const errObj = await aiRes.json().catch(() => ({}));
        console.error('OpenAI Error:', aiRes.status, errObj);
        throw new Error(`OpenAI Error: ${aiRes.statusText}`);
    }

    const aiData = await aiRes.json();
    let textResult = aiData.choices[0].message.content.trim();

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
