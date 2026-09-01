-- ASAM order persistence.
-- Orders belong to the authenticated owner and reference the existing clients/products tables.

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  client_id uuid not null references public.clients(id) on delete restrict,
  order_date date not null default current_date,
  status text not null default 'completed' check (status in ('draft', 'confirmed', 'completed', 'cancelled')),
  total_amount numeric(14,2) not null default 0 check (total_amount >= 0),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  quantity numeric(14,3) not null check (quantity > 0),
  unit_price numeric(14,2) not null check (unit_price >= 0),
  created_at timestamptz not null default now()
);

create index if not exists orders_owner_date_idx
  on public.orders(owner_id, order_date desc, created_at desc);

create index if not exists orders_client_idx
  on public.orders(client_id);

create index if not exists order_items_order_idx
  on public.order_items(order_id);

create index if not exists order_items_product_idx
  on public.order_items(product_id);

alter table public.orders enable row level security;
alter table public.order_items enable row level security;

drop policy if exists orders_owner_select on public.orders;
drop policy if exists orders_owner_insert on public.orders;
drop policy if exists orders_owner_update on public.orders;
drop policy if exists orders_owner_delete on public.orders;

drop policy if exists order_items_owner_select on public.order_items;
drop policy if exists order_items_owner_insert on public.order_items;
drop policy if exists order_items_owner_update on public.order_items;
drop policy if exists order_items_owner_delete on public.order_items;

create policy orders_owner_select
  on public.orders for select
  to authenticated
  using ((select auth.uid()) = owner_id);

create policy orders_owner_insert
  on public.orders for insert
  to authenticated
  with check ((select auth.uid()) = owner_id);

create policy orders_owner_update
  on public.orders for update
  to authenticated
  using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);

create policy orders_owner_delete
  on public.orders for delete
  to authenticated
  using ((select auth.uid()) = owner_id);

create policy order_items_owner_select
  on public.order_items for select
  to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and o.owner_id = (select auth.uid())
    )
  );

create policy order_items_owner_insert
  on public.order_items for insert
  to authenticated
  with check (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and o.owner_id = (select auth.uid())
    )
  );

create policy order_items_owner_update
  on public.order_items for update
  to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and o.owner_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and o.owner_id = (select auth.uid())
    )
  );

create policy order_items_owner_delete
  on public.order_items for delete
  to authenticated
  using (
    exists (
      select 1 from public.orders o
      where o.id = order_items.order_id
        and o.owner_id = (select auth.uid())
    )
  );

grant select, insert, update, delete on public.orders to authenticated;
grant select, insert, update, delete on public.order_items to authenticated;
