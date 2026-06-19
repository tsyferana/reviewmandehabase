-- Ce script met à jour la table reviews pour supporter les fils de discussion (réponses multiples)
-- Copiez et collez ce script dans l'éditeur SQL (SQL Editor) de votre tableau de bord Supabase, puis exécutez-le.

-- 1. Ajouter la colonne JSONB 'replies' si elle n'existe pas
ALTER TABLE public.reviews 
ADD COLUMN IF NOT EXISTS replies JSONB DEFAULT '[]'::jsonb;

-- 2. Migrer l'ancienne colonne 'owner_reply' vers 'replies' (si elle existe et contient des données)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'reviews' AND column_name = 'owner_reply') THEN
    UPDATE public.reviews
    SET replies = jsonb_build_array(
      jsonb_build_object(
        'senderRole', 'owner',
        'message', owner_reply,
        'createdAt', created_at -- ou utiliser current_timestamp si préféré
      )
    )
    WHERE owner_reply IS NOT NULL AND owner_reply != '';
    
    -- Optionnel : Supprimer l'ancienne colonne une fois migrée
    -- ALTER TABLE public.reviews DROP COLUMN owner_reply;
  END IF;
END $$;

-- 3. Mettre à jour la politique RLS pour permettre à la fois aux clients et aux propriétaires de mettre à jour le fil
-- Les clients ne peuvent mettre à jour que leurs propres avis.
-- Le code Flutter s'assure que seules les "replies" sont modifiées lors d'une réponse.
DROP POLICY IF EXISTS "Enable update for owner replies" ON public.reviews;

CREATE POLICY "Enable updates for replies thread" 
ON public.reviews FOR UPDATE 
TO authenticated 
USING (true)
WITH CHECK (true);
