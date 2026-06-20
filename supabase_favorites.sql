-- Création de la table favorites (si elle n'existe pas)
CREATE TABLE IF NOT EXISTS public.favorites (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    -- Empêche un utilisateur d'ajouter deux fois la même entreprise
    UNIQUE(user_id, business_id)
);

-- Activation du RLS
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

-- Les utilisateurs peuvent voir leurs propres favoris
CREATE POLICY "Users can view their own favorites" 
ON public.favorites FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

-- Les utilisateurs peuvent ajouter un favori pour eux-mêmes
CREATE POLICY "Users can insert their own favorites" 
ON public.favorites FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

-- Les utilisateurs peuvent supprimer leurs propres favoris
CREATE POLICY "Users can delete their own favorites" 
ON public.favorites FOR DELETE 
TO authenticated 
USING (auth.uid() = user_id);
