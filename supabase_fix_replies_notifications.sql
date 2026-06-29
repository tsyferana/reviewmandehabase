-- ==============================================================================
-- CORRECTION DU SYSTÈME DE NOTIFICATIONS POUR LES RÉPONSES (FILS DE DISCUSSION)
-- ==============================================================================

-- A exécuter dans l'éditeur SQL de Supabase pour corriger les notifications
-- après la migration vers le système de réponses en fil de discussion (colonne `replies`).

CREATE OR REPLACE FUNCTION public.trigger_notify_on_reply()
RETURNS TRIGGER AS $$
DECLARE
  v_business_name TEXT;
  v_owner_id UUID;
  v_latest_reply JSONB;
  v_sender_role TEXT;
BEGIN
  -- Vérifier si le tableau 'replies' a grandi (une nouvelle réponse a été ajoutée)
  IF jsonb_typeof(NEW.replies) = 'array' AND 
     (OLD.replies IS NULL OR jsonb_typeof(OLD.replies) != 'array' OR jsonb_array_length(NEW.replies) > jsonb_array_length(OLD.replies)) THEN
    
    -- Récupérer les informations de l'entreprise (nom et ID du propriétaire)
    SELECT name, owner_id INTO v_business_name, v_owner_id
    FROM public.businesses
    WHERE id = NEW.business_id;

    -- Récupérer la dernière réponse ajoutée (le dernier élément du tableau)
    v_latest_reply := NEW.replies->(jsonb_array_length(NEW.replies) - 1);
    v_sender_role := v_latest_reply->>'senderRole';

    IF v_sender_role = 'owner' THEN
      -- Le propriétaire a répondu, notifier le client
      INSERT INTO public.notifications (user_id, title, message, type, related_id)
      VALUES (
        NEW.user_id,
        'Nouvelle réponse',
        'Le propriétaire de ' || v_business_name || ' a répondu à votre avis.',
        'reply',
        NEW.business_id
      );
    ELSIF v_sender_role = 'client' AND v_owner_id IS NOT NULL THEN
      -- Le client a répondu, notifier le propriétaire de l'entreprise
      INSERT INTO public.notifications (user_id, title, message, type, related_id)
      VALUES (
        v_owner_id,
        'Nouveau message',
        'Un client a répondu dans le fil de discussion de votre entreprise ' || v_business_name || '.',
        'reply',
        NEW.business_id
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Supprimer l'ancien trigger s'il existe
DROP TRIGGER IF EXISTS on_review_replied ON public.reviews;

-- Créer le nouveau trigger
CREATE TRIGGER on_review_replied
AFTER UPDATE ON public.reviews
FOR EACH ROW EXECUTE FUNCTION public.trigger_notify_on_reply();
