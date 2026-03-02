-- Script to fix teacher materials upload issue
-- 1. Create the 'study_materials' bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'study_materials', 
    'study_materials', 
    true, 
    52428800, -- 50MB limit
    ARRAY['application/pdf', 'image/png', 'image/jpeg', 'image/jpg', 'video/mp4'] -- Restricted types for safety
)
ON CONFLICT (id) DO UPDATE SET 
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 2. Create standardized RLS policies for storage objects in this bucket

-- Drop existing policies to avoid conflicts/duplicates
DROP POLICY IF EXISTS "Public Access Study Materials" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Upload Study Materials" ON storage.objects;
DROP POLICY IF EXISTS "Owner Update Study Materials" ON storage.objects;
DROP POLICY IF EXISTS "Owner Delete Study Materials" ON storage.objects;

-- Policy: Anyone can read/download (since public=true, but RLS still applies to list/get operations in some configs)
CREATE POLICY "Public Access Study Materials"
ON storage.objects FOR SELECT
USING ( bucket_id = 'study_materials' );

-- Policy: Any authenticated user can upload
-- Note: In a real app, you might restrict this to users with role 'teacher' or 'admin'.
-- Assuming authenticated users are valid uploaders for now.
CREATE POLICY "Authenticated Upload Study Materials"
ON storage.objects FOR INSERT
WITH CHECK ( 
    bucket_id = 'study_materials' 
    AND auth.role() = 'authenticated' 
);

-- Policy: Users can update their own files
CREATE POLICY "Owner Update Study Materials"
ON storage.objects FOR UPDATE
USING ( bucket_id = 'study_materials' AND auth.uid() = owner )
WITH CHECK ( bucket_id = 'study_materials' AND auth.uid() = owner );

-- Policy: Users can delete their own files
CREATE POLICY "Owner Delete Study Materials"
ON storage.objects FOR DELETE
USING ( bucket_id = 'study_materials' AND auth.uid() = owner );
