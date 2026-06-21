-- ==============================================================================
-- 1. CREATION DE LA TABLE NOTIFICATIONS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL, -- 'review', 'reply', 'business_request', 'approval', 'rejection', 'report'
    related_id UUID, -- ID de l'entreprise ou de l'avis concerné
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 2. SECURITE (RLS)
-- ==============================================================================
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Les utilisateurs peuvent voir et modifier (marquer comme lu) leurs propres notifications
CREATE POLICY "Users can view own notifications" 
ON public.notifications FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" 
ON public.notifications FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own notifications" 
ON public.notifications FOR DELETE 
USING (auth.uid() = user_id);

-- Les triggers systèmes et administrateurs auront besoin d'insérer des notifications
-- L'insertion se fait via des fonctions SECURITY DEFINER ou par les admins
CREATE POLICY "Admins can insert notifications" 
ON public.notifications FOR INSERT 
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND account_type = 'admin'
  )
);

-- ==============================================================================
-- 3. AUTOMATISATIONS (TRIGGERS)
-- ==============================================================================

-- A. Notification au propriétaire quand un avis est publié
CREATE OR REPLACE FUNCTION public.trigger_notify_on_new_review()
RETURNS TRIGGER AS $$
DECLARE
  v_owner_id UUID;
  v_business_name TEXT;
BEGIN
  -- Récupérer l'ID du propriétaire et le nom de l'entreprise
  SELECT owner_id, name INTO v_owner_id, v_business_name
  FROM public.businesses
  WHERE id = NEW.business_id;

  -- Créer la notification si l'entreprise a un propriétaire et que ce n'est pas lui-même qui laisse l'avis
  IF v_owner_id IS NOT NULL AND v_owner_id != NEW.user_id THEN
    INSERT INTO public.notifications (user_id, title, message, type, related_id)
    VALUES (
      v_owner_id,
      'Nouvel avis',
      'Un client a laissé un avis de ' || NEW.rating || ' étoiles sur votre entreprise ' || v_business_name || '.',
      'review',
      NEW.business_id
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_review_created ON public.reviews;
CREATE TRIGGER on_review_created
AFTER INSERT ON public.reviews
FOR EACH ROW EXECUTE FUNCTION public.trigger_notify_on_new_review();


-- B. Notification à l'auteur de l'avis quand le propriétaire répond
-- Supposons que la réponse est mise dans une colonne "owner_reply" de la table reviews
CREATE OR REPLACE FUNCTION public.trigger_notify_on_owner_reply()
RETURNS TRIGGER AS $$
DECLARE
  v_business_name TEXT;
BEGIN
  -- Vérifier si la réponse du propriétaire a été ajoutée (passe de null à not null, ou modifiée)
  IF NEW.owner_reply IS NOT NULL AND (OLD.owner_reply IS NULL OR OLD.owner_reply != NEW.owner_reply) THEN
    -- Récupérer le nom de l'entreprise
    SELECT name INTO v_business_name
    FROM public.businesses
    WHERE id = NEW.business_id;

    -- Notifier l'auteur de l'avis
    INSERT INTO public.notifications (user_id, title, message, type, related_id)
    VALUES (
      NEW.user_id,
      'Réponse du propriétaire',
      'Le propriétaire de ' || v_business_name || ' a répondu à votre avis.',
      'reply',
      NEW.business_id
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_review_replied ON public.reviews;
CREATE TRIGGER on_review_replied
AFTER UPDATE ON public.reviews
FOR EACH ROW EXECUTE FUNCTION public.trigger_notify_on_owner_reply();


-- C. Notifications sur l'état d'une entreprise (Création, Approbation, Rejet)
CREATE OR REPLACE FUNCTION public.trigger_notify_on_business_status()
RETURNS TRIGGER AS $$
DECLARE
  v_admin_record RECORD;
BEGIN
  -- 1. L'entreprise vient d'être soumise (création)
  IF TG_OP = 'INSERT' AND NEW.status = 'pending' THEN
    -- Notifier tous les administrateurs
    FOR v_admin_record IN SELECT id FROM public.profiles WHERE account_type = 'admin' LOOP
      INSERT INTO public.notifications (user_id, title, message, type, related_id)
      VALUES (
        v_admin_record.id,
        'Nouvelle entreprise à valider',
        'L''entreprise "' || NEW.name || '" vient d''être soumise et attend votre validation.',
        'business_request',
        NEW.id
      );
    END LOOP;
  END IF;

  -- 2. L'entreprise est approuvée ou rejetée (mise à jour)
  IF TG_OP = 'UPDATE' AND OLD.status != NEW.status AND NEW.owner_id IS NOT NULL THEN
    IF NEW.status = 'approved' THEN
      INSERT INTO public.notifications (user_id, title, message, type, related_id)
      VALUES (
        NEW.owner_id,
        'Entreprise validée !',
        'Félicitations, votre entreprise "' || NEW.name || '" a été approuvée.',
        'approval',
        NEW.id
      );
    ELSIF NEW.status = 'rejected' THEN
      INSERT INTO public.notifications (user_id, title, message, type, related_id)
      VALUES (
        NEW.owner_id,
        'Entreprise refusée',
        'Votre entreprise "' || NEW.name || '" n''a pas été approuvée. Veuillez vérifier les règles.',
        'rejection',
        NEW.id
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_business_status_changed ON public.businesses;
CREATE TRIGGER on_business_status_changed
AFTER INSERT OR UPDATE ON public.businesses
FOR EACH ROW EXECUTE FUNCTION public.trigger_notify_on_business_status();
