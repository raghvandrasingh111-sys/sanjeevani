# Supabase backend setup for Sanjeevni

1. Create a project at [supabase.com](https://supabase.com).
2. In **Project Settings → API**, copy the **Project URL** and **anon public** key into `lib/utils/constants.dart`:
   - `supabaseUrl` = Project URL  
   - `supabaseAnonKey` = anon public key

3. In the Supabase **SQL Editor**, run the script below.

4. In **Storage**, create a bucket named `prescriptions` and set it to **Public** (or add a policy that allows public read and authenticated upload/delete as needed).

5. **Login without email verification:** In **Authentication → Providers → Email**, turn **OFF** "Confirm email" if you want users to log in right after sign up without clicking a confirmation link. If you leave it ON, the app will show a message asking them to confirm their email first.

---

## SQL script (run in SQL Editor)

```sql
-- Enable UUID extension if not already
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Profiles (extends auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  name TEXT NOT NULL,
  user_type TEXT NOT NULL CHECK (user_type IN ('patient', 'doctor')),
  phone TEXT,
  profile_image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Prescriptions
CREATE TABLE IF NOT EXISTS public.prescriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  doctor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  notes TEXT,
  ai_summary TEXT,
  medications TEXT[],
  dosage TEXT,
  instructions TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.prescriptions ENABLE ROW LEVEL SECURITY;

-- Profiles: users can read/update their own row; insert only for own id
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Prescriptions: doctors/patients see their related rows
CREATE POLICY "Users can view prescriptions where they are doctor or patient"
  ON public.prescriptions FOR SELECT
  USING (auth.uid() = doctor_id OR auth.uid() = patient_id);

CREATE POLICY "Authenticated users can insert prescriptions"
  ON public.prescriptions FOR INSERT
  WITH CHECK (auth.uid() = doctor_id);

CREATE POLICY "Doctors can delete prescriptions they created"
  ON public.prescriptions FOR DELETE
  USING (auth.uid() = doctor_id);

-- Trigger to create profile on signup (uses name/user_type from signUp data)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, user_type)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
    COALESCE(NEW.raw_user_meta_data->>'user_type', 'patient')
  )
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    user_type = EXCLUDED.user_type,
    updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

The app passes `name` and `user_type` in sign-up and upserts the profile so it works with or without the trigger.

---

## Storage bucket `prescriptions`

1. Go to **Storage** in the Supabase dashboard.
2. New bucket: name = `prescriptions`, set to **Public** if you want public read URLs (the app uses `getPublicUrl`).
3. Add a policy if not public, for example:
   - **SELECT**: allow public or authenticated.
   - **INSERT**: allow authenticated.
   - **DELETE**: allow authenticated (and optionally restrict by user).

After this, run `flutter pub get` and configure `Constants.supabaseUrl` and `Constants.supabaseAnonKey` in `lib/utils/constants.dart`.
