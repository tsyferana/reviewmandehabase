-- Create business_views table to track page views
CREATE TABLE IF NOT EXISTS public.business_views (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  business_id UUID REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Add index for faster counting and filtering
CREATE INDEX IF NOT EXISTS business_views_business_id_idx ON public.business_views(business_id);
CREATE INDEX IF NOT EXISTS business_views_created_at_idx ON public.business_views(created_at);

-- Grant necessary privileges to the API roles
GRANT SELECT, INSERT ON public.business_views TO anon, authenticated;

-- RLS policies
ALTER TABLE public.business_views ENABLE ROW LEVEL SECURITY;

-- Drop policies in case the script is run multiple times
DROP POLICY IF EXISTS "Anyone can insert a view" ON public.business_views;
DROP POLICY IF EXISTS "Business owners can view their stats" ON public.business_views;

-- Anyone can insert a view (authenticated or not)
CREATE POLICY "Anyone can insert a view"
ON public.business_views FOR INSERT
WITH CHECK (true);

-- Business owners can read their own views
CREATE POLICY "Business owners can view their stats"
ON public.business_views FOR SELECT
USING (
  business_id IN (
    SELECT id FROM public.businesses WHERE owner_id = auth.uid()
  )
);
