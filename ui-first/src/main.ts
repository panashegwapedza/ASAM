import './styles.css';

type View = 'dashboard' | 'products' | 'clients' | 'orders' | 'marketing' | 'alerts';
type Product = { name: string; sku: string; price: number };
type Order = { id: string; product: Product; client: string; quantity: number; total: number; status: string };

const state: { view: View; products: Product[]; clients: string[]; orders: Order[]; selectedProduct?: Product } = {
  view: 'dashboard',
  products: [
    { name: 'Premium Sugar 2kg', sku: 'SUG-002', price: 3.5 },
    { name: 'Cooking Oil 2L', sku: 'OIL-002', price: 5.2 },
    { name: 'Laundry Soap', sku: 'SOAP-001', price: 2.1 },
  ],
  clients: ['Mbare Grocers', 'Sunrise Mini Mart', 'Tendai Stores'],
  orders: [],
};

const app = document.querySelector<HTMLDivElement>('#app')!;
const money = (n: number) => `$${n.toFixed(2)}`;

function navItem(view: View, label: string, icon: string) {
  return `<button class="nav-item ${state.view === view ? 'active' : ''}" data-view="${view}"><span>${icon}</span>${label}</button>`;
}

function render() {
  app.innerHTML = `<div class="shell"><aside class="sidebar"><div class="brand"><span class="brand-mark">e</span><div><strong>ASAM</strong><small>Sales & Marketing</small></div></div><nav>${navItem('dashboard','Dashboard','⌂')}${navItem('products','Products','□')}${navItem('clients','Clients','♙')}${navItem('orders','Orders','▤')}${navItem('marketing','Marketing','◌')}${navItem('alerts','Alerts','△')}</nav><div class="sidebar-foot">MVP workspace<br><span>Local mode</span></div></aside><main class="main"><header class="topbar"><div><span class="eyebrow">ASAM workspace</span><h1>${pageTitle()}</h1></div><button class="avatar">PG</button></header><section class="content">${pageContent()}</section></main></div>`;
  document.querySelectorAll<HTMLButtonElement>('[data-view]').forEach(btn => btn.onclick = () => { state.view = btn.dataset.view as View; state.selectedProduct = undefined; render(); });
  document.querySelectorAll<HTMLButtonElement>('[data-order]').forEach(btn => btn.onclick = () => { state.selectedProduct = state.products[Number(btn.dataset.order)]; render(); });
  document.querySelectorAll<HTMLButtonElement>('[data-place-order]').forEach(btn => btn.onclick = () => placeOrder());
}

function pageTitle() { return ({dashboard:'Good morning',products:'Products',clients:'Clients',orders:'Orders',marketing:'Marketing',alerts:'Alerts'} as Record<View,string>)[state.view]; }

function pageContent() {
  if (state.selectedProduct) return orderFlow();
  if (state.view === 'dashboard') return `<div class="hero"><div><span class="eyebrow">Today</span><h2>Run the day from one place.</h2><p>Track customers, products, orders and follow-ups without the clutter.</p></div><button class="primary" data-view="products">Start with products →</button></div><div class="metrics"><article><span>Orders</span><strong>${state.orders.length}</strong><small>Created in this session</small></article><article><span>Clients</span><strong>${state.clients.length}</strong><small>Active accounts</small></article><article><span>Products</span><strong>${state.products.length}</strong><small>In catalogue</small></article><article><span>Attention</span><strong>3</strong><small>Needs follow-up</small></article></div><div class="section-head"><div><span class="eyebrow">Core workflow</span><h3>Quick actions</h3></div></div><div class="quick-grid"><button data-view="products"><b>Products</b><span>Choose a product and start an order.</span></button><button data-view="clients"><b>Clients</b><span>Manage customer relationships.</span></button><button data-view="orders"><b>Orders</b><span>Review recent orders and status.</span></button><button data-view="marketing"><b>Marketing</b><span>Work through today's follow-ups.</span></button></div>`;

  if (state.view === 'products') return `<div class="section-head"><div><span class="eyebrow">Catalogue</span><h2>Products</h2><p>Choose a product to view details or place an order.</p></div><button class="primary">+ Add product</button></div><div class="product-grid">${state.products.map((p,i)=>`<article class="product-card"><div class="product-icon">${p.name[0]}</div><div><span class="sku">${p.sku}</span><h3>${p.name}</h3><strong>${money(p.price)}</strong></div><button class="order-btn" data-order="${i}">Order</button></article>`).join('')}</div>`;

  if (state.view === 'clients') return `<div class="section-head"><div><span class="eyebrow">Relationships</span><h2>Clients</h2><p>Your customer accounts and supply relationships.</p></div><button class="primary">+ Add client</button></div><div class="list">${state.clients.map((c,i)=>`<div class="list-row"><div class="initial">${c[0]}</div><div><strong>${c}</strong><small>${i===0?'Regular buyer':'Active account'}</small></div><span class="status">Active</span></div>`).join('')}</div>`;

  if (state.view === 'orders') return `<div class="section-head"><div><span class="eyebrow">Transactions</span><h2>Orders</h2><p>Orders created during this local MVP session.</p></div><button class="primary" data-view="products">+ New order</button></div>${state.orders.length ? `<div class="list">${state.orders.map(o=>`<div class="list-row"><div class="initial">${o.product.name[0]}</div><div><strong>${o.client}</strong><small>${o.product.name} · Qty ${o.quantity} · ${money(o.total)}</small></div><span class="status">${o.status}</span></div>`).join('')}</div>` : `<div class="empty-state"><div>▤</div><h3>No orders yet</h3><p>Start from Products and place your first order.</p><button class="primary" data-view="products">Create first order</button></div>`}`;

  if (state.view === 'marketing') return `<div class="section-head"><div><span class="eyebrow">Follow-ups</span><h2>Marketing</h2><p>Stay on top of customer conversations and opportunities.</p></div></div><div class="list"><div class="list-row"><div class="priority">!</div><div><strong>Follow up with Mbare Grocers</strong><small>Check remaining Cooking Oil stock</small></div><button class="ghost">Complete</button></div><div class="list-row"><div class="priority">!</div><div><strong>Contact Sunrise Mini Mart</strong><small>Reorder discussion</small></div><button class="ghost">Complete</button></div></div>`;
  return `<div class="section-head"><div><span class="eyebrow">Attention</span><h2>Alerts</h2><p>Signals that need your attention.</p></div></div><div class="list"><div class="list-row"><div class="priority">!</div><div><strong>Reorder signal</strong><small>Mbare Grocers may need Cooking Oil soon.</small></div><button class="ghost">Review</button></div><div class="list-row"><div class="priority">!</div><div><strong>Follow-up overdue</strong><small>Sunrise Mini Mart has an outstanding follow-up.</small></div><button class="ghost">Review</button></div></div>`;
}

function orderFlow() {
  const p = state.selectedProduct!;
  return `<div class="section-head"><div><button class="back" id="back-products">← Products</button><span class="eyebrow">New order</span><h2>Order ${p.name}</h2><p>${p.sku} · ${money(p.price)} each</p></div></div><div class="order-layout"><div class="order-card"><div class="step"><span>1</span><div><b>Choose client</b><small>Who is this order for?</small></div></div><div class="client-options">${state.clients.map((c,i)=>`<label class="client-option"><input type="radio" name="client" value="${c}" ${i===0?'checked':''}><span>${c}</span></label>`).join('')}</div><div class="step"><span>2</span><div><b>Quantity</b><small>How many units?</small></div></div><div class="quantity"><button id="qty-minus">−</button><strong id="qty-value">1</strong><button id="qty-plus">+</button></div></div><aside class="summary"><span class="eyebrow">Order summary</span><h3>${p.name}</h3><div class="summary-line"><span>Unit price</span><strong>${money(p.price)}</strong></div><div class="summary-line"><span>Quantity</span><strong id="summary-qty">1</strong></div><div class="total"><span>Total</span><strong id="summary-total">${money(p.price)}</strong></div><button class="primary place" data-place-order>Place Order</button></aside></div>`;
}

function placeOrder() {
  const p = state.selectedProduct!;
  const client = document.querySelector<HTMLInputElement>('input[name="client"]:checked')?.value;
  const quantity = Number(document.querySelector('#qty-value')?.textContent ?? '1');
  if (!client) return;
  state.orders.unshift({ id:`ORD-${Date.now()}`, product:p, client, quantity, total:p.price*quantity, status:'Placed' });
  state.selectedProduct = undefined; state.view = 'orders'; render();
  app.querySelector('.content')?.insertAdjacentHTML('afterbegin','<div class="success">✓ Order placed successfully</div>');
}

render();

app.addEventListener('click', e => {
  const target = e.target as HTMLElement;
  if (target.id === 'back-products') { state.selectedProduct = undefined; state.view='products'; render(); return; }
  if (target.id === 'qty-minus' || target.id === 'qty-plus') {
    const el = document.querySelector('#qty-value'); if (!el) return;
    let q = Number(el.textContent); q = target.id === 'qty-plus' ? q + 1 : Math.max(1,q-1); el.textContent=String(q);
    const p=state.selectedProduct!; document.querySelector('#summary-qty')!.textContent=String(q); document.querySelector('#summary-total')!.textContent=money(p.price*q);
  }
});
