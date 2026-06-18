-- Ce script permet de configurer les règles de sécurité (RLS) pour que les clients puissent publier des avis
-- Copiez et collez ce script dans l'éditeur SQL (SQL Editor) de votre tableau de bord Supabase, puis exécutez-le.

-- 1. Règles pour la table 'reviews'
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Permettre à tout le monde de lire les avis
CREATE POLICY "Enable read access for all users" 
ON public.reviews FOR SELECT 
TO public 
USING (true);

-- Permettre aux utilisateurs connectés d'ajouter un avis en leur nom
CREATE POLICY "Enable insert for authenticated users" 
ON public.reviews FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

-- Permettre aux utilisateurs de modifier leurs propres avis
CREATE POLICY "Enable update for own reviews" 
ON public.reviews FOR UPDATE 
TO authenticated 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Permettre aux utilisateurs de supprimer leurs propres avis
CREATE POLICY "Enable delete for own reviews" 
ON public.reviews FOR DELETE 
TO authenticated 
USING (auth.uid() = user_id);


-- 2. Règles pour la table 'businesses'
-- L'application met à jour la note moyenne (rating) et le nombre d'avis (review_count) 
-- directement depuis le client lorsqu'un avis est posté.
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;

-- Autoriser la mise à jour des entreprises par les utilisateurs connectés
-- (Dans un environnement de production, il faudrait utiliser une fonction (Trigger) côté serveur, 
--  mais pour le moment cela permet à l'application de fonctionner telle quelle).
CREATE POLICY "Enable update for stats" 
ON public.businesses FOR UPDATE 
TO authenticated 
USING (true);


-- 3. (Optionnel) Règles pour le stockage des photos d'avis (bucket: reviews_photos)
-- Permettre aux utilisateurs connectés de téléverser des images
CREATE POLICY "Enable insert for review photos" 
ON storage.objects FOR INSERT 
TO authenticated 
WITH CHECK (bucket_id = 'reviews_photos');

-- Permettre à tout le monde de voir les images
CREATE POLICY "Enable read for review photos" 
ON storage.objects FOR SELECT 
TO public 
USING (bucket_id = 'reviews_photos');
