-- Fonction qui recalcule la moyenne et le nombre d'avis d'une entreprise
CREATE OR REPLACE FUNCTION public.update_business_rating()
RETURNS TRIGGER AS $$
BEGIN
  -- Met à jour les statistiques de l'entreprise
  UPDATE public.businesses
  SET 
    review_count = (
      SELECT count(*) FROM public.reviews WHERE business_id = COALESCE(NEW.business_id, OLD.business_id)
    ),
    rating = COALESCE((
      SELECT avg(rating) FROM public.reviews WHERE business_id = COALESCE(NEW.business_id, OLD.business_id)
    ), 0.0)
  WHERE id = COALESCE(NEW.business_id, OLD.business_id);
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
-- L'utilisation de SECURITY DEFINER permet à la fonction d'outrepasser les règles RLS
-- (afin que même un simple client puisse déclencher la mise à jour de l'entreprise)

-- Supprimer le déclencheur s'il existe déjà
DROP TRIGGER IF EXISTS trigger_update_business_rating ON public.reviews;

-- Créer le déclencheur qui s'exécute après chaque modification d'avis
CREATE TRIGGER trigger_update_business_rating
AFTER INSERT OR UPDATE OR DELETE ON public.reviews
FOR EACH ROW EXECUTE FUNCTION public.update_business_rating();
