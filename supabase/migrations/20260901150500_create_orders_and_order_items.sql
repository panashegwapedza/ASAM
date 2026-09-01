-- ASAM order workflow hardening.
-- orders and order_items already exist in the initial ASAM schema.
-- This migration only adds the missing child-row index needed by the order workflow.

create index if not exists order_items_order_idx
  on public.order_items(order_id);
