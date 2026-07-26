-- Security and Content Protection Tables

-- Table for tracking bound devices
CREATE TABLE IF NOT EXISTS public.user_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_identifier TEXT NOT NULL,
    device_name TEXT,
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, device_identifier)
);

-- Enable RLS on user_devices
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own devices" ON public.user_devices
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own devices" ON public.user_devices
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own devices" ON public.user_devices
    FOR UPDATE USING (auth.uid() = user_id);

-- Table for tracking audit logs of content access
CREATE TYPE content_type_enum AS ENUM ('video', 'pdf', 'image', 'audio', 'exam', 'unknown');

CREATE TABLE IF NOT EXISTS public.content_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content_id UUID NOT NULL,
    content_type content_type_enum DEFAULT 'unknown',
    device_identifier TEXT NOT NULL,
    ip_address TEXT,
    action TEXT NOT NULL, -- e.g., 'view_started', 'download_offline', 'screenshot_detected'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS on content_audit_logs
ALTER TABLE public.content_audit_logs ENABLE ROW LEVEL SECURITY;

-- Users can only insert logs for themselves (e.g., from the client app)
CREATE POLICY "Users can insert their own audit logs" ON public.content_audit_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Only admins/super_admins can read audit logs.
-- Assuming an `is_admin` or similar function exists in the ecosystem.
-- CREATE POLICY "Admins can view all logs" ON public.content_audit_logs FOR SELECT USING (is_admin());
