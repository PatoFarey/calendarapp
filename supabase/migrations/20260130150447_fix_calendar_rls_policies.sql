/*
  # Fix Calendar RLS Policies
  
  1. Remove existing restrictive policies that are blocking all access
  2. Add proper RLS policies that allow:
     - Users to read their own calendars
     - Users to read shared calendars
     - Users to create, update, delete their own calendars
*/

DROP POLICY IF EXISTS "Users can read own calendars" ON calendars;
DROP POLICY IF EXISTS "Users can insert own calendars" ON calendars;
DROP POLICY IF EXISTS "Users can update own calendars" ON calendars;
DROP POLICY IF EXISTS "Users can delete own calendars" ON calendars;

CREATE POLICY "Users can read own calendars"
  ON calendars
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own calendars"
  ON calendars
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own calendars"
  ON calendars
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own calendars"
  ON calendars
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

create policy "public read calendars"
on public.calendars
for select
to anon
using (is_public = true);

create policy "public read bookings"
on public.bookings
for select
to anon
using (
  calendar_id in (select id from public.calendars where is_public = true)
);
