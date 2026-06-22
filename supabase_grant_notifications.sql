-- Accorder les permissions nécessaires aux rôles de l'API Supabase
GRANT ALL ON public.notifications TO authenticated;
GRANT ALL ON public.notifications TO anon;
GRANT ALL ON public.notifications TO service_role;
