-- ═══════════════════════════════════════════════════════════════════
--  DEPLOMAT 2K26 · Secure public Check-Registration search (RPC)
--  Run this ONCE in: Supabase Dashboard → SQL Editor → New query
--
--  WHAT THIS DOES
--  --------------
--  1. Creates a SECURITY DEFINER function `search_registrations_public`
--     that the public reg-status.html page calls instead of querying the
--     registrations table directly.
--  2. Accepts:  p_phone (REQUIRED)  ·  p_college · p_event_name ·
--               p_team_leader (all optional)
--  3. Normalizes phone numbers before comparison so +91, spaces, hyphens
--     and parentheses are ignored (last-10-digit match for country codes).
--  4. Returns ONLY the minimum fields the public page displays:
--     event_name, event_sub, college, ug_pu, team_leader, phone,
--     total_amount, txn, participants, status, registered_at.
--     It never returns email, rejection_reason, verified_at, or any
--     internal/admin fields.
--  5. Rate-limit friendly: max 50 rows per call.
--  6. Locks down the table: revokes direct SELECT from anon on
--     registrations so the public can only reach data through this RPC.
--     Admin/coordinator dashboards keep working because they use the
--     same anon key BUT this change removes their table access too!
--
--  ⚠️  IMPORTANT BEFORE RUNNING STEP 6:
--  The admin dashboard (admindb.html) and student coordinator page
--  (sco.html) currently use the SAME anon/publishable key and read the
--  registrations table directly. Revoking anon SELECT will break them
--  UNLESS you either
--      (a) keep the SELECT grant (table readable, but public check page
--          still only exposes data via this RPC — recommended only if
--          you accept the current admin setup), or
--      (b) move the admin dashboard to an authenticated role / service
--          backend (the proper long-term fix).
--  Step 6 is provided as a separate, clearly-marked optional block.
-- ═══════════════════════════════════════════════════════════════════

-- ── 1. THE RPC ───────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.search_registrations_public(
    p_phone       text,
    p_college     text DEFAULT NULL,
    p_event_name  text DEFAULT NULL,
    p_team_leader text DEFAULT NULL
)
RETURNS TABLE (
    id            bigint,
    event_name    text,
    event_sub     text,
    college       text,
    ug_pu         text,
    team_leader   text,
    phone         text,
    total_amount  integer,
    txn           text,
    participants  jsonb,
    status        text,
    registered_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_phone_digits text := regexp_replace(coalesce(p_phone, ''), '\D', '', 'g');
    v_phone_last10 text := right(v_phone_digits, 10);
BEGIN
    -- Phone is mandatory: refuse to search without it
    IF v_phone_digits IS NULL OR length(v_phone_digits) < 10 THEN
        RAISE EXCEPTION 'A valid phone number is required';
    END IF;

    RETURN QUERY
    SELECT
        r.id,
        r.event_name,
        r.event_sub,
        r.college,
        r.ug_pu,
        r.team_leader,
        r.phone,
        r.total_amount,
        r.txn,
        r.participants,
        r.status,
        r.registered_at
    FROM registrations r
    WHERE
        -- Phone match, format-tolerant:
        --   digits equal, OR last-10 digits equal (ignores +91 etc.)
        (regexp_replace(coalesce(r.phone, ''), '\D', '', 'g') = v_phone_digits
         OR (length(v_phone_last10) = 10
             AND right(regexp_replace(coalesce(r.phone, ''), '\D', '', 'g'), 10) = v_phone_last10))

      -- Optional case-insensitive substring filters
      AND (p_college     IS NULL OR p_college     = ''
           OR r.college     ILIKE '%' || p_college     || '%')
      AND (p_event_name  IS NULL OR p_event_name  = ''
           OR r.event_name  ILIKE '%' || p_event_name  || '%')
      AND (p_team_leader IS NULL OR p_team_leader = ''
           OR r.team_leader ILIKE '%' || p_team_leader || '%')

    ORDER BY r.registered_at DESC
    LIMIT 50;
END;
$$;

-- ── 2. EXECUTE PERMISSION FOR ANON (public page) ─────────────────────
GRANT EXECUTE ON FUNCTION public.search_registrations_public(text, text, text, text)
    TO anon, authenticated;

-- ── 3. (OPTIONAL — read the warning above before running) ────────────
-- Lock direct table reads away from anonymous users so the ONLY public
-- path to registration data is this RPC. Uncomment the lines below to
-- enforce it.
--
-- REVOKE ALL ON TABLE public.registrations FROM anon;
--
-- If your admin dashboard uses the anon key directly, ALSO run this so
-- it keeps working, understanding that it re-grants public read access:
--
-- GRANT SELECT ON TABLE public.registrations TO anon;
--
-- (The safest setup is: leave SELECT revoked, and have the admin
--  dashboard sign in with an authenticated role that has its own
--  SELECT policy.)
