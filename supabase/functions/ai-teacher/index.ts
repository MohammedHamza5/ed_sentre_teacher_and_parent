import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.38.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// --- Models ---
const MODELS: Record<string, string> = {
  'qwen-max': 'qwen-max',
  'qwen-plus': 'qwen-plus',
  'qwen-turbo': 'qwen-turbo',
};

// Validate that a model is allowed for the teacher function
function getValidModel(requestedModel: string | undefined): string {
  if (requestedModel && MODELS[requestedModel]) {
    return MODELS[requestedModel];
  }
  return MODELS['qwen-max']; // Default fallback to max
}

// --- DashScope Helper for File Upload ---
async function uploadToDashScope(fileBlob: Blob, dashscopeApiKey: string): Promise<string> {
  const formData = new FormData();
  formData.append('file', fileBlob, 'document.pdf');
  formData.append('purpose', 'file-extract');

  const response = await fetch('https://dashscope-intl.aliyuncs.com/compatible-mode/v1/files', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${dashscopeApiKey}`,
    },
    body: formData,
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error('DashScope upload error:', errorText);
    throw new Error(`Failed to upload file to DashScope: ${response.statusText} - ${errorText}`);
  }

  const data = await response.json();
  if (!data.id) {
    throw new Error('No file id returned from DashScope');
  }

  return data.id; // Returns the file-id (e.g., file-xxxx)
}


serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { task, content, params, model, file_path, difficulty } = await req.json();
    const finalFilePath = file_path || params?.file_path;
    const finalDifficulty = difficulty || params?.difficulty;

    const DASH_SCOPE_KEY = Deno.env.get('DASHSCOPE_API_KEY') || Deno.env.get('QWEN_API_KEY');
    if (!DASH_SCOPE_KEY) {
      throw new Error('DASHSCOPE_API_KEY or QWEN_API_KEY is missing from Edge Function secrets.');
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // Default messages array
    const messages: any[] = [];
    let activeModel = getValidModel(model);

    // 1. SYSTEM PROMPT: Teacher Persona
    const baseSystemPrompt = `أنت مساعد ذكي مخصص لمعلم مصري. اسمك 'المساعد الذكي للمعلم'.
مهامك الرئيسية التفكير كمعلم خبير بأسلوب واضح ومهني وبلهجة عربية فصحى مع لمسة مصرية بسيطة إذا لزم الأمر في الشرح.
يجب أن تركز دائماً على إفادة الطالب مساعدة المعلم في التحضير والتقييم وتحليل الأداء.`;
    
    messages.push({ role: 'system', content: baseSystemPrompt });

    // 2. CHECK FOR FILE ATTACHMENT (PDF)
    if (finalFilePath) {
      console.log(`Downloading file from storage: ${finalFilePath}`);
      const { data: fileData, error: downloadError } = await supabaseClient.storage
        .from('ai_documents')
        .download(finalFilePath);

      if (downloadError || !fileData) {
        throw new Error(`Failed to download file from Storage: ${downloadError?.message}`);
      }

      console.log(`Uploading file to DashScope...`);
      const fileId = await uploadToDashScope(fileData, DASH_SCOPE_KEY);
      console.log(`DashScope returned file_id: ${fileId}`);

      // Add the file to the system prompt
      messages.push({
        role: 'system',
        content: `fileid://${fileId}`
      });

      // Override model to ensure we use max for documents
      activeModel = MODELS['qwen-max']; 
    }


    // 3. TASK HANDLERS
    if (task === 'generate_exam') {
      const qCount = params?.questionCount ?? 10;
      const exactDifficulty = finalDifficulty || 'medium';
      
      let diffText = 'متوسط';
      if(exactDifficulty === 'easy') diffText = 'سهل جداً ومباشر';
      else if(exactDifficulty === 'hard') diffText = 'صعب ويحتاج تفكير عميق (مستوى المتفوقين)';
      else if(exactDifficulty === 'mixed') diffText = 'متنوع (30% سهل، 50% متوسط، 20% صعب)';

      const examPrompt = `قم بإنشاء امتحان مكون من ${qCount} أسئلة من نوع (اختيار من متعدد وصح أو خطأ) بناءً على ${finalFilePath ? 'الملف المرفق' : 'المحتوى التالي'}.
مستوى الصعوبة المطلوب: ${diffText}.

${finalFilePath ? 'ركز بشكل أساسي على محتوى الملف المرفق واستخرج الأسئلة منه.' : `المحتوى:
${content}`}

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
      "correct_answer": 0, // 0 for True (صح), 1 for False (خطأ)
      "difficulty": "${exactDifficulty}",
      "marks": 2
    }
  ]
}
الخرد يجب أن يكون JSON فقط بدون أي نصوص قبلها أو بعدها.
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
        messages.push({ role: 'user', content: content }); // Fallback
    }

    // Call Qwen DashScope
    console.log(`Calling DashScope with model: ${activeModel}, task: ${task}`);
    
    // Note: DashScope's OpenAI compatible URL 
    const dashScopeUrl = 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions';

    const aiRes = await fetch(dashScopeUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${DASH_SCOPE_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: activeModel,
        messages: messages,
        temperature: task === 'generate_exam' ? 0.2 : 0.7, // Lower temperature for structured JSON
        max_tokens: 4000
      })
    });

    if (!aiRes.ok) {
        const errObj = await aiRes.json().catch(() => ({}));
        console.error('DashScope AI Response Error:', aiRes.status, errObj);
        throw new Error(`Qwen AI Error: ${aiRes.statusText}`);
    }

    const aiData = await aiRes.json();
    let textResult = aiData.choices[0].message.content.trim();

    // Clean JSON formatting if requesting exam
    if (task === 'generate_exam' || task === 'generate_assignment' || task === 'analyze_performance') {
        // Strip markdown code brackets if present
        if (textResult.startsWith('```json')) {
            textResult = textResult.substring(7);
        } else if (textResult.startsWith('```')) {
            textResult = textResult.substring(3);
        }
        if (textResult.endsWith('```')) {
            textResult = textResult.substring(0, textResult.length - 3);
        }
        textResult = textResult.trim();
        
        try{
            // Just verifying it's parseable
            JSON.parse(textResult);
        } catch(e) {
            console.error('Failed to parse AI JSON:', textResult);
            throw new Error('AI did not return valid JSON.');
        }
    }

    return new Response(JSON.stringify({ result: textResult }), {
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
