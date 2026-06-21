-- Activer le temps réel (Realtime) pour la table notifications

-- Essayer d'ajouter la table à la publication Realtime
-- (Si vous obtenez une erreur disant que la table y est déjà, vous pouvez l'ignorer)
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
