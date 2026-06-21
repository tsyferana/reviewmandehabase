-- 1. On ajoute les colonnes si elles ont été oubliées lors de la création de la table
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS rating NUMERIC DEFAULT 0.0;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS review_count INTEGER DEFAULT 0;

-- 2. On recalcule toutes les statistiques pour le passé
UPDATE public.businesses b
SET 
  review_count = (
    SELECT count(*) 
    FROM public.reviews r 
    WHERE r.business_id = b.id
  ),
  rating = COALESCE((
    SELECT avg(rating) 
    FROM public.reviews r 
    WHERE r.business_id = b.id
  ), 0.0);
