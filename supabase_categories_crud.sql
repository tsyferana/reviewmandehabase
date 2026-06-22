-- ==============================================================================
-- ACTIVER LE CRUD POUR LES CATEGORIES (ADMIN)
-- ==============================================================================

-- 1. S'assurer que le Row Level Security est activé
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- 2. Tout le monde peut lire les catégories
DROP POLICY IF EXISTS "Categories are viewable by everyone" ON public.categories;
CREATE POLICY "Categories are viewable by everyone" 
ON public.categories FOR SELECT 
USING (true);

-- 3. Seuls les administrateurs peuvent insérer des catégories
DROP POLICY IF EXISTS "Admins can insert categories" ON public.categories;
CREATE POLICY "Admins can insert categories" 
ON public.categories FOR INSERT 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND account_type = 'admin'
  )
);

-- 4. Seuls les administrateurs peuvent mettre à jour des catégories
DROP POLICY IF EXISTS "Admins can update categories" ON public.categories;
CREATE POLICY "Admins can update categories" 
ON public.categories FOR UPDATE 
USING (
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND account_type = 'admin'
  )
);

-- 5. Seuls les administrateurs peuvent supprimer des catégories
DROP POLICY IF EXISTS "Admins can delete categories" ON public.categories;
CREATE POLICY "Admins can delete categories" 
ON public.categories FOR DELETE 
USING (
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND account_type = 'admin'
  )
);

-- Note: Donner l'accès de base au rôle authentifié pour être sûr (éviter l'erreur de permissions PostgREST)
GRANT ALL ON public.categories TO authenticated;
GRANT SELECT ON public.categories TO anon;
