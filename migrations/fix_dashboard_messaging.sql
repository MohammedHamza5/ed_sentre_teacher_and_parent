-- Fix RLS for conversations and messages to correctly handle Teacher Business ID vs Auth ID

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Conversations Policy
DROP POLICY IF EXISTS "Users can view their own conversations" ON public.conversations;

CREATE POLICY "Users can view their own conversations"
ON public.conversations
FOR SELECT
USING (
  (student_id = auth.uid()) OR 
  (teacher_id IN (SELECT id FROM public.teachers WHERE user_id = auth.uid()))
);

-- Messages Policy
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON public.messages;

CREATE POLICY "Users can view messages in their conversations"
ON public.messages
FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE c.id = messages.conversation_id
    AND (
      (c.student_id = auth.uid()) OR 
      (c.teacher_id IN (SELECT id FROM public.teachers WHERE user_id = auth.uid()))
    )
  )
);
