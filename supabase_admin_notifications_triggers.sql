-- =========================================================================
-- TRIGGERS DE NOTIFICATIONS ADMIN
-- =========================================================================

-- Notification aux admins lors d'un nouveau signalement (report)
CREATE OR REPLACE FUNCTION public.notify_admins_new_report()
RETURNS TRIGGER AS $$
DECLARE
  v_admin_record RECORD;
BEGIN
  -- Notifier tous les administrateurs
  FOR v_admin_record IN SELECT id FROM public.profiles WHERE account_type = 'admin' LOOP
    INSERT INTO public.notifications (user_id, title, message, type, related_id)
    VALUES (
      v_admin_record.id,
      'Nouveau signalement',
      'Un avis a été signalé pour : ' || NEW.report_type || '. Raison : ' || NEW.reason,
      'report',
      NEW.id
    );
  END LOOP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_report_inserted ON public.reports;
CREATE TRIGGER on_report_inserted
AFTER INSERT ON public.reports
FOR EACH ROW EXECUTE FUNCTION public.notify_admins_new_report();
