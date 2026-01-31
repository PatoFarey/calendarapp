/*
  # Clean Duplicate and Fix RLS Policies
  
  1. Remove duplicate policies
  2. Fix policies that directly query auth.users (causes permission errors)
  3. Use only necessary policies
*/

DROP POLICY IF EXISTS "Users can delete their own calendars" ON calendars;
DROP POLICY IF EXISTS "Users can insert their own calendars" ON calendars;
DROP POLICY IF EXISTS "Users can update their own calendars" ON calendars;
DROP POLICY IF EXISTS "Users can view their own calendars" ON calendars;
DROP POLICY IF EXISTS "Users can view shared calendars" ON calendars;

DROP POLICY IF EXISTS "Users can create bookings in shared calendars if they have edit" ON bookings;
DROP POLICY IF EXISTS "Users can view bookings in shared calendars" ON bookings;
