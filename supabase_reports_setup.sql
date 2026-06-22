-- =========================================================================
-- SYSTEME DE SIGNALEMENT (REPORTS)
-- =========================================================================

-- 1. Création de la table 'reports'
CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_id UUID NOT NULL REFERENCES public.reviews(id) ON DELETE CASCADE,
    reporter_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN ('false_review', 'spam', 'offensive', 'incorrect_info')),
    reason TEXT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'handled')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Empêcher le même utilisateur de signaler le même avis plusieurs fois
    UNIQUE (review_id, reporter_id)
);

-- 2. Fonction et Trigger pour mettre à jour 'updated_at'
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DO $$ BEGIN
    CREATE TRIGGER update_reports_updated_at
    BEFORE UPDATE ON public.reports
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. Sécurité et Politiques RLS (Row Level Security)
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- Les utilisateurs authentifiés peuvent créer un signalement
CREATE POLICY "Authenticated users can insert reports" 
    ON public.reports FOR INSERT 
    WITH CHECK (auth.role() = 'authenticated');

-- Les administrateurs peuvent tout voir
CREATE POLICY "Admins can view all reports" 
    ON public.reports FOR SELECT 
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid() AND profiles.account_type = 'admin'
        )
    );

-- Les administrateurs peuvent mettre à jour le statut des signalements
CREATE POLICY "Admins can update reports" 
    ON public.reports FOR UPDATE 
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid() AND profiles.account_type = 'admin'
        )
    );

-- Les administrateurs peuvent supprimer des signalements
CREATE POLICY "Admins can delete reports" 
    ON public.reports FOR DELETE 
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid() AND profiles.account_type = 'admin'
        )
    );

-- =========================================================================
-- DROITS ADMIN SUR LA TABLE REVIEWS (SUPPRESSION D'AVIS)
-- =========================================================================
-- Il faut s'assurer que les administrateurs peuvent supprimer un avis (reviews)
-- On ajoute une policy DELETE sur la table 'reviews'

DROP POLICY IF EXISTS "Admins can delete reviews" ON public.reviews;
CREATE POLICY "Admins can delete reviews"
    ON public.reviews FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid() AND profiles.account_type = 'admin'
        )
    );
