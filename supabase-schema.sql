-- ═══════════════════════════════════════════════════════════
-- FINCONSULT — Schema Supabase
-- Execute esse SQL no SQL Editor do Supabase
-- ═══════════════════════════════════════════════════════════

-- 1. TABELA DE PERFIS (extends auth.users)
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  full_name TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL DEFAULT '',
  phone TEXT DEFAULT '',
  cpf TEXT DEFAULT '',
  birth_date DATE,
  occupation TEXT DEFAULT '',
  monthly_goal NUMERIC(12,2) DEFAULT 0,
  notes TEXT DEFAULT '',
  role TEXT NOT NULL DEFAULT 'client' CHECK (role IN ('consultant', 'client')),
  consultant_id UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. RECEITAS
CREATE TABLE public.incomes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  month TEXT NOT NULL, -- '2026-04'
  category TEXT NOT NULL DEFAULT 'Outros',
  description TEXT DEFAULT '',
  value NUMERIC(12,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. DESPESAS
CREATE TABLE public.expenses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  month TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'Outros',
  description TEXT DEFAULT '',
  value NUMERIC(12,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. DÍVIDAS
CREATE TABLE public.debts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL DEFAULT '',
  total_value NUMERIC(12,2) DEFAULT 0,
  current_balance NUMERIC(12,2) DEFAULT 0,
  monthly_payment NUMERIC(12,2) DEFAULT 0,
  interest_rate NUMERIC(6,4) DEFAULT 0,
  start_date TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. INVESTIMENTOS
CREATE TABLE public.investments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL DEFAULT '',
  type TEXT DEFAULT '',
  current_value NUMERIC(12,2) DEFAULT 0,
  monthly_contribution NUMERIC(12,2) DEFAULT 0,
  expected_return NUMERIC(6,4) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. LANÇAMENTOS DO CONTROLE DIÁRIO
CREATE TABLE public.control_entries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
  type TEXT NOT NULL DEFAULT 'despesa' CHECK (type IN ('receita', 'despesa')),
  category TEXT NOT NULL DEFAULT 'Outros',
  description TEXT DEFAULT '',
  value NUMERIC(12,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS)
-- Cliente vê só os próprios dados
-- Consultor vê os dados dos seus clientes
-- ═══════════════════════════════════════════════════════════

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incomes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.debts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.investments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.control_entries ENABLE ROW LEVEL SECURITY;

-- Helper: checa se o usuário logado é consultor de um determinado user_id
CREATE OR REPLACE FUNCTION public.is_consultant_of(target_user_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = target_user_id
      AND consultant_id = auth.uid()
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Helper: checa se o usuário logado é consultor
CREATE OR REPLACE FUNCTION public.is_consultant()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'consultant'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ── PROFILES POLICIES ──
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (id = auth.uid());

CREATE POLICY "Consultants can view their clients"
  ON public.profiles FOR SELECT
  USING (consultant_id = auth.uid());

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (id = auth.uid());

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (id = auth.uid());

-- ── MACRO: políticas para tabelas financeiras ──
-- Cada tabela segue o mesmo padrão: dono vê/edita + consultor vê

-- INCOMES
CREATE POLICY "Owner select incomes" ON public.incomes FOR SELECT USING (user_id = auth.uid() OR public.is_consultant_of(user_id));
CREATE POLICY "Owner insert incomes" ON public.incomes FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Owner update incomes" ON public.incomes FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Owner delete incomes" ON public.incomes FOR DELETE USING (user_id = auth.uid());

-- EXPENSES
CREATE POLICY "Owner select expenses" ON public.expenses FOR SELECT USING (user_id = auth.uid() OR public.is_consultant_of(user_id));
CREATE POLICY "Owner insert expenses" ON public.expenses FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Owner update expenses" ON public.expenses FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Owner delete expenses" ON public.expenses FOR DELETE USING (user_id = auth.uid());

-- DEBTS
CREATE POLICY "Owner select debts" ON public.debts FOR SELECT USING (user_id = auth.uid() OR public.is_consultant_of(user_id));
CREATE POLICY "Owner insert debts" ON public.debts FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Owner update debts" ON public.debts FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Owner delete debts" ON public.debts FOR DELETE USING (user_id = auth.uid());

-- INVESTMENTS
CREATE POLICY "Owner select investments" ON public.investments FOR SELECT USING (user_id = auth.uid() OR public.is_consultant_of(user_id));
CREATE POLICY "Owner insert investments" ON public.investments FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Owner update investments" ON public.investments FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Owner delete investments" ON public.investments FOR DELETE USING (user_id = auth.uid());

-- CONTROL_ENTRIES
CREATE POLICY "Owner select entries" ON public.control_entries FOR SELECT USING (user_id = auth.uid() OR public.is_consultant_of(user_id));
CREATE POLICY "Owner insert entries" ON public.control_entries FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Owner update entries" ON public.control_entries FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Owner delete entries" ON public.control_entries FOR DELETE USING (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════
-- TRIGGER: criar perfil automaticamente no signup
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'client')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ═══════════════════════════════════════════════════════════
-- INDEXES para performance
-- ═══════════════════════════════════════════════════════════

CREATE INDEX idx_incomes_user_month ON public.incomes(user_id, month);
CREATE INDEX idx_expenses_user_month ON public.expenses(user_id, month);
CREATE INDEX idx_debts_user ON public.debts(user_id);
CREATE INDEX idx_investments_user ON public.investments(user_id);
CREATE INDEX idx_control_entries_user_date ON public.control_entries(user_id, entry_date);
CREATE INDEX idx_profiles_consultant ON public.profiles(consultant_id);
