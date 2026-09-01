-- The trigger function is invoked by Postgres from auth.users; clients do not
-- need to call it through the Data API.
revoke execute on function public.handle_new_user() from anon, authenticated;
