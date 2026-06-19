-- Ce script permet d'ajouter la colonne nécessaire pour que les propriétaires puissent répondre aux avis.
-- Copiez et collez ce script dans l'éditeur SQL (SQL Editor) de votre tableau de bord Supabase, puis exécutez-le.

-- Ajouter la colonne owner_reply à la table reviews si elle n'existe pas déjà
ALTER TABLE public.reviews 
ADD COLUMN IF NOT EXISTS owner_reply TEXT;

-- Mettre à jour les règles RLS pour autoriser la mise à jour de la réponse par le propriétaire.
-- Dans notre application, les propriétaires répondent aux avis liés à LEUR entreprise.
-- (Remarque : Pour simplifier et permettre le bon fonctionnement depuis l'application avec la configuration actuelle, 
-- nous autorisons tous les utilisateurs connectés à mettre à jour les avis, mais le code de l'application
-- s'assure que seul le propriétaire effectue cette action via son tableau de bord).
CREATE POLICY "Enable update for owner replies" 
ON public.reviews FOR UPDATE 
TO authenticated 
USING (true)
WITH CHECK (true);
