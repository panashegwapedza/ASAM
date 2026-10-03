create or replace function public.wren_product_code(p_name text)
returns text
language plpgsql
immutable
as $$
declare
  words text[];
  w text;
  code text := '';
  cleaned text;
begin
  if p_name is null or btrim(p_name) = '' then return 'P'; end if;
  cleaned := regexp_replace(lower(p_name), '[^a-z[:space:]]', ' ', 'g');
  words := regexp_split_to_array(regexp_replace(cleaned, '\s+', ' ', 'g'), ' ');
  foreach w in array words loop
    if w is null or w = '' then continue; end if;
    if w in ('ml','l','kg','g','mg','litre','litres','liter','liters','unit','units','case','cases','box','boxes','drum','drums','container','containers') then continue; end if;
    code := code || upper(left(w,1));
  end loop;
  if code = '' then return 'P'; end if;
  return code;
end;
$$;

update public.orders o
set order_number =
  to_char(coalesce(o.order_date::date,o.created_at::date),'YYMMDD')
  || public.wren_product_code(coalesce(p.name,'Product'))
  || lpad(substring(o.order_number from '(\d{4})$'),4,'0')
from (
  select distinct on (oi.order_id) oi.order_id, p.name
  from public.order_items oi
  join public.products p on p.id=oi.product_id
  order by oi.order_id, oi.id
) p
where p.order_id=o.id and o.order_number is not null;
