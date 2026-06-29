-- ==============================================================================
-- CORRECTION DES POLITIQUES RLS POUR LES FAVORIS (VUES PAR L'ENTREPRISE)
-- ==============================================================================

-- A exécuter dans l'éditeur SQL de Supabase.
-- Cette politique permet aux propriétaires d'entreprises de pouvoir compter/voir
-- les favoris qui concernent leurs propres entreprises, afin que le tableau de bord
-- (dashboard) affiche correctement le nombre total de favoris.

CREATE POLICY "Business owners can view favorites for their business" 
ON public.favorites FOR SELECT 
TO authenticated 
USING (
  business_id IN (
    SELECT id FROM public.businesses WHERE owner_id = auth.uid()
  )
);
