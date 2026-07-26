-- RPC function to register a new device and revoke all previous devices for the user
CREATE OR REPLACE FUNCTION public.register_user_device(
    p_device_identifier TEXT,
    p_device_name TEXT DEFAULT 'Unknown Device'
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER -- Runs as the database owner so it can bypass RLS for the update
AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Get the currently authenticated user's ID
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    -- Deactivate all existing devices for this user
    UPDATE public.user_devices
    SET is_active = false
    WHERE user_id = v_user_id;

    -- Insert or update the current device to be active
    INSERT INTO public.user_devices (user_id, device_identifier, device_name, is_active, last_active_at)
    VALUES (v_user_id, p_device_identifier, p_device_name, true, NOW())
    ON CONFLICT (user_id, device_identifier)
    DO UPDATE SET 
        is_active = true,
        last_active_at = NOW(),
        device_name = EXCLUDED.device_name;
END;
$$;
