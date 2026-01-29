-- Illinois Farmlink App - Dev seed (local / db reset only)
-- Use: supabase db reset (local) or run manually on hosted dev after creating Auth users.
-- Does NOT run on production. For hosted dev, create users in Dashboard then run the profile/listing inserts below with their IDs.

-- Optional: for LOCAL Supabase only (supabase start + db reset), uncomment to create test auth users.
-- Passwords: use Supabase Dashboard Auth or extension to set; this seed does not create auth users on hosted.

-- Placeholder UUIDs for dev (replace with real auth.users.id after creating users in Dashboard if running on hosted):
-- Admin:  11111111-1111-1111-1111-111111111111
-- Farmer: 22222222-2222-2222-2222-222222222222
-- Owner:  33333333-3333-3333-3333-333333333333

DO $$
DECLARE
  admin_id  uuid := '11111111-1111-1111-1111-111111111111';
  farmer_id uuid := '22222222-2222-2222-2222-222222222222';
  owner_id  uuid := '33333333-3333-3333-3333-333333333333';
  inst_id   uuid;
  listing_id uuid;
BEGIN
  SELECT id INTO inst_id FROM auth.instances LIMIT 1;
  IF inst_id IS NULL THEN
    RAISE NOTICE 'Seed: auth.instances empty; skipping auth.users insert (expected on first local start).';
    RETURN;
  END IF;

  -- Insert test users into auth.users (local only; may fail on hosted due to permissions)
  INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at
  ) VALUES
    (inst_id, admin_id, 'authenticated', 'authenticated', 'admin@farmlink-dev.local',
     crypt('DevPassword123!', gen_salt('bf')), now(), '{"provider":"email"}', '{}', now(), now()),
    (inst_id, farmer_id, 'authenticated', 'authenticated', 'farmer@farmlink-dev.local',
     crypt('DevPassword123!', gen_salt('bf')), now(), '{"provider":"email"}', '{}', now(), now()),
    (inst_id, owner_id, 'authenticated', 'authenticated', 'landowner@farmlink-dev.local',
     crypt('DevPassword123!', gen_salt('bf')), now(), '{"provider":"email"}', '{}', now(), now())
  ON CONFLICT (id) DO NOTHING;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Seed auth.users skipped (e.g. hosted or already seeded): %', SQLERRM;
END $$;

-- Profiles (depend on auth.users; use same placeholder UUIDs)
INSERT INTO public.profiles (id, role, status, first_name, last_name, state, terms_accepted)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'admin', 'approved', 'Admin', 'User', 'IL', true),
  ('22222222-2222-2222-2222-222222222222', 'farmer', 'approved', 'Dev', 'Farmer', 'IL', true),
  ('33333333-3333-3333-3333-333333333333', 'landowner', 'approved', 'Dev', 'Landowner', 'IL', true)
ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role, status = EXCLUDED.status, first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name, state = EXCLUDED.state, terms_accepted = EXCLUDED.terms_accepted;

INSERT INTO public.farmer_profiles (profile_id, farming_status, counties, crops, referral_source)
VALUES ('22222222-2222-2222-2222-222222222222', 'seeking land', ARRAY['Cook','Will'], ARRAY['vegetables','grains'], 'dev seed')
ON CONFLICT (profile_id) DO UPDATE SET
  farming_status = EXCLUDED.farming_status, counties = EXCLUDED.counties, crops = EXCLUDED.crops;

INSERT INTO public.landowner_profiles (profile_id, referral_source)
VALUES ('33333333-3333-3333-3333-333333333333', 'dev seed')
ON CONFLICT (profile_id) DO NOTHING;

-- One approved listing (owner = landowner)
INSERT INTO public.listings (
  id, owner_profile_id, status, property_name, street_address, city, state, zip, county,
  total_acreage, farmable_acreage, crops_permitted, preferred_farming_methods, zoning_appropriate
) VALUES (
  '44444444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333', 'approved',
  'Dev Farm', '123 Seed Rd', 'Chicago', 'IL', '60601', 'Cook',
  40, 35, ARRAY['vegetables','grains'], ARRAY['organic','sustainable'], true
)
ON CONFLICT (id) DO NOTHING;
