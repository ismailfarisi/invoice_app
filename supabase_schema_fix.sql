-- Enable RLS and Fix Schema for Flutter Invoice App

-- 1. Business Profiles
ALTER TABLE IF EXISTS public.business_profiles ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE IF EXISTS public.business_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own business profile" ON public.business_profiles;
CREATE POLICY "Users can manage their own business profile" 
ON public.business_profiles FOR ALL 
USING (auth.uid() = user_id);

-- 2. Clients
ALTER TABLE IF EXISTS public.clients ADD COLUMN IF NOT EXISTS "contactPerson" TEXT;
ALTER TABLE IF EXISTS public.clients ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE IF EXISTS public.clients ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own clients" ON public.clients;
CREATE POLICY "Users can manage their own clients" 
ON public.clients FOR ALL 
USING (auth.uid() = user_id);

-- 3. Products
ALTER TABLE IF EXISTS public.products ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE IF EXISTS public.products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own products" ON public.products;
CREATE POLICY "Users can manage their own products" 
ON public.products FOR ALL 
USING (auth.uid() = user_id);

-- 4. Invoices
ALTER TABLE IF EXISTS public.invoices ADD COLUMN IF NOT EXISTS "client_id" TEXT REFERENCES public.clients(id) ON DELETE SET NULL;
ALTER TABLE IF EXISTS public.invoices ADD COLUMN IF NOT EXISTS "invoiceNumber" TEXT;
ALTER TABLE IF EXISTS public.invoices ADD COLUMN IF NOT EXISTS "dueDate" TIMESTAMPTZ;
ALTER TABLE IF EXISTS public.invoices ADD COLUMN IF NOT EXISTS "termsAndConditions" TEXT;
ALTER TABLE IF EXISTS public.invoices ADD COLUMN IF NOT EXISTS "salesPerson" TEXT;
ALTER TABLE IF EXISTS public.invoices ADD COLUMN IF NOT EXISTS "isVatApplicable" BOOLEAN DEFAULT TRUE;
ALTER TABLE IF EXISTS public.invoices ADD COLUMN IF NOT EXISTS "placeOfSupply" TEXT;
ALTER TABLE IF EXISTS public.invoices ADD COLUMN IF NOT EXISTS "deliveryNote" TEXT;
ALTER TABLE IF EXISTS public.invoices ADD COLUMN IF NOT EXISTS "paymentTerms" TEXT;
ALTER TABLE IF EXISTS public.invoices ADD COLUMN IF NOT EXISTS "supplierReference" TEXT;
ALTER TABLE IF EXISTS public.invoices ADD COLUMN IF NOT EXISTS "otherReference" TEXT;
ALTER TABLE IF EXISTS public.invoices ADD COLUMN IF NOT EXISTS "buyersOrderNumber" TEXT;
ALTER TABLE IF EXISTS public.invoices ADD COLUMN IF NOT EXISTS "buyersOrderDate" TIMESTAMPTZ;
ALTER TABLE IF EXISTS public.invoices ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE IF EXISTS public.invoices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own invoices" ON public.invoices;
CREATE POLICY "Users can manage their own invoices" 
ON public.invoices FOR ALL 
USING (auth.uid() = user_id);

-- 5. Invoice Items
ALTER TABLE IF EXISTS public.invoice_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own invoice items" ON public.invoice_items;
CREATE POLICY "Users can manage their own invoice items" 
ON public.invoice_items FOR ALL 
USING (auth.uid() = user_id);

-- 6. Quotations
ALTER TABLE IF EXISTS public.quotations ADD COLUMN IF NOT EXISTS "client_id" TEXT REFERENCES public.clients(id) ON DELETE SET NULL;
ALTER TABLE IF EXISTS public.quotations ADD COLUMN IF NOT EXISTS "quotationNumber" TEXT;
ALTER TABLE IF EXISTS public.quotations ADD COLUMN IF NOT EXISTS "validUntil" TIMESTAMPTZ;
ALTER TABLE IF EXISTS public.quotations ADD COLUMN IF NOT EXISTS "enquiryRef" TEXT;
ALTER TABLE IF EXISTS public.quotations ADD COLUMN IF NOT EXISTS "project" TEXT;
ALTER TABLE IF EXISTS public.quotations ADD COLUMN IF NOT EXISTS "termsAndConditions" TEXT;
ALTER TABLE IF EXISTS public.quotations ADD COLUMN IF NOT EXISTS "salesPerson" TEXT;
ALTER TABLE IF EXISTS public.quotations ADD COLUMN IF NOT EXISTS "isVatApplicable" BOOLEAN DEFAULT TRUE;
ALTER TABLE IF EXISTS public.quotations ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE IF EXISTS public.quotations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own quotations" ON public.quotations;
CREATE POLICY "Users can manage their own quotations" 
ON public.quotations FOR ALL 
USING (auth.uid() = user_id);

-- 7. Quotation Items
ALTER TABLE IF EXISTS public.quotation_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own quotation items" ON public.quotation_items;
CREATE POLICY "Users can manage their own quotation items" 
ON public.quotation_items FOR ALL 
USING (auth.uid() = user_id);

-- 8. LPOs
ALTER TABLE IF EXISTS public.lpos ADD COLUMN IF NOT EXISTS "vendor_id" TEXT REFERENCES public.clients(id) ON DELETE SET NULL;
ALTER TABLE IF EXISTS public.lpos ADD COLUMN IF NOT EXISTS "lpoNumber" TEXT;
ALTER TABLE IF EXISTS public.lpos ADD COLUMN IF NOT EXISTS "expectedDeliveryDate" TIMESTAMPTZ;
ALTER TABLE IF EXISTS public.lpos ADD COLUMN IF NOT EXISTS "placeOfSupply" TEXT;
ALTER TABLE IF EXISTS public.lpos ADD COLUMN IF NOT EXISTS "paymentTerms" TEXT;
ALTER TABLE IF EXISTS public.lpos ADD COLUMN IF NOT EXISTS "otherReference" TEXT;
ALTER TABLE IF EXISTS public.lpos ADD COLUMN IF NOT EXISTS "termsAndConditions" TEXT;
ALTER TABLE IF EXISTS public.lpos ADD COLUMN IF NOT EXISTS "salesPerson" TEXT;
ALTER TABLE IF EXISTS public.lpos ADD COLUMN IF NOT EXISTS "isVatApplicable" BOOLEAN DEFAULT TRUE;
ALTER TABLE IF EXISTS public.lpos ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE IF EXISTS public.lpos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own lpos" ON public.lpos;
CREATE POLICY "Users can manage their own lpos" 
ON public.lpos FOR ALL 
USING (auth.uid() = user_id);

-- 9. LPO Items
ALTER TABLE IF EXISTS public.lpo_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own lpo items" ON public.lpo_items;
CREATE POLICY "Users can manage their own lpo items" 
ON public.lpo_items FOR ALL 
USING (auth.uid() = user_id);

-- 10. Proformas
ALTER TABLE IF EXISTS public.proformas ADD COLUMN IF NOT EXISTS "client_id" TEXT REFERENCES public.clients(id) ON DELETE SET NULL;
ALTER TABLE IF EXISTS public.proformas ADD COLUMN IF NOT EXISTS "proformaNumber" TEXT;
ALTER TABLE IF EXISTS public.proformas ADD COLUMN IF NOT EXISTS "validUntil" TIMESTAMPTZ;
ALTER TABLE IF EXISTS public.proformas ADD COLUMN IF NOT EXISTS "project" TEXT;
ALTER TABLE IF EXISTS public.proformas ADD COLUMN IF NOT EXISTS "termsAndConditions" TEXT;
ALTER TABLE IF EXISTS public.proformas ADD COLUMN IF NOT EXISTS "salesPerson" TEXT;
ALTER TABLE IF EXISTS public.proformas ADD COLUMN IF NOT EXISTS "isVatApplicable" BOOLEAN DEFAULT TRUE;
ALTER TABLE IF EXISTS public.proformas ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE IF EXISTS public.proformas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage their own proformas" ON public.proformas;
CREATE POLICY "Users can manage their own proformas" 
ON public.proformas FOR ALL 
USING (auth.uid() = user_id);

-- 11. Proforma Items
ALTER TABLE IF EXISTS public.proforma_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage their own proforma items" ON public.proforma_items;
CREATE POLICY "Users can manage their own proforma items" 
ON public.proforma_items FOR ALL 
USING (auth.uid() = user_id);
