import './styles.css';

type View = 'dashboard' | 'products' | 'clients' | 'orders' | 'marketing' | 'alerts';

const state = {
  view: 'dashboard' as View,
  products: [
    { name: 'Premium Sugar 2kg', sku: 'SUG-002', price: 3.5 },
    { name: 'Cooking Oil 2L', sku: 'OIL-002', price: 5.2 },
    { name: 'Laundry Soap', sku: 'SOAP-001', price: 2.1 },
  ],
  clients: ['Mbare Grocers', 'Sunrise Mini Mart', 'Tendai Stores'],
  orders: 12,
};

const app = document.querySelector<HTMLDivElement>('#app')!;

function navItem(view: View, label: string, icon: string) {
  return `<button class="nav-item ${state.view === view ? 'active' : ''}" data-view="${view}"><span>${icon}</span>${label}</button>`;
}

function render() {
  app.innerHTML = `
    <div class="shell">
      <aside class="sidebar">
        <div class="brand"><span class="brand-mark">e</span><div><strong>ASAM</strong><small>Sales & Marketing</small></div></div>
        <nav>
          ${navItem('dashboard', 'Dashboard', '⌂')}
          ${navItem('products', 'Products', '□')}
          ${navItem('clients', 'Clients', '♙')}
          ${navItem('orders', 'Orders', '▤')}
          ${navItem('marketing', 'Marketing', '◌')}
          ${navItem('alerts', 'Alerts', '△')}
        </nav>
        <div class="sidebar-foot">MVP workspace<br><span>Local mode</span></div>
      </aside>
      <main class="main">
        <header class="topbar"><div><span class="eyebrow">ASAM workspace</span><h1>${pageTitle()}</h1></div><button class="avatar">PG</button></header>
        <section class="content">${pageContent()}</section>
      </main>
    </div>`;

  document.querySelectorAll<HTMLButtonElement>('[data-view]').forEach(btn => btn.onclick = () => {
    state.view = btn.dataset.view as View; render();
  });
}

function pageTitle() {
  return ({ dashboard: 'Good morning', products: 'Products', clients: 'Clients', orders: 'Orders', marketing: 'Marketing', alerts: 'Alerts' } as Record<View,string>)[state.view];
}

function pageContent() {
  if (state.view === 'dashboard') return `<div class="hero"><div><span class="eyebrow">Today</span><h2>Run the day from one place.</h2><p>Track customers, products, orders and follow-ups without the clutter.</p></div><button class="primary" data-view="products">Manage products →</button></div>
    <div class="metrics"><article><span>Orders</span><strong>${state.orders}</strong><small>This period</small></article><article><span>Clients</span><strong>${state.clients.length}</strong><small>Active accounts</small></article><article><span>Products</span><strong>${state.products.length}</strong><small>In catalogue</small></article><article><span>Attention</span><strong>3</strong><small>Needs follow-up</small></article></div>
    <div class="section-head"><div><span class="eyebrow">Core workflow</span><h3>Quick actions</h3></div></div><div class="quick-grid"><button data-view="products"><b>Products</b><span>Choose a product and start an order.</span></button><button data-view="clients"><b>Clients</b><span>Manage customer relationships.</span></button><button data-view="orders"><b>Orders</b><span>Review recent orders and status.</span></button><button data-view="marketing"><b>Marketing</b><span>Work through today's follow-ups.</span></button></div>`;

  if (state.view === 'products') return `<div class="section-head"><div><span class="eyebrow">Catalogue</span><h2>Products</h2><p>Choose a product to view details or place an order.</p></div><button class="primary" id="add-product">+ Add product</button></div><div class="product-grid">${state.products.map((p,i)=>`<article class="product-card"><div class="product-icon">${p.name[0]}</div><div><span class="sku">${p.sku}</span><h3>${p.name}</h3><strong>$${p.price.toFixed(2)}</strong></div><button class="order-btn" data-order="${i}">Order</button></article>`).join('')}</div>`;

  if (state.view === 'clients') return `<div class="section-head"><div><span class="eyebrow">Relationships</span><h2>Clients</h2><p>Your customer accounts and supply relationships.</p></div><button class="primary">+ Add client</button></div><div class="list">${state.clients.map((c,i)=>`<div class="list-row"><div class="initial">${c[0]}</div><div><strong>${c}</strong><small>${i === 0 ? 'Regular buyer' : 'Active account'}</small></div><span class="status">Active</span></div>`).join('')}</div>`;

  if (state.view === 'orders') return `<div class="section-head"><div><span class="eyebrow">Transactions</span><h2>Orders</h2><p>Recent customer orders.</p></div></div><div class="empty-state"><div>▤</div><h3>${state.orders} orders recorded</h3><p>Order history will become fully persistent when the backend is connected.</p></div>`;
  if (state.view === 'marketing') return `<div class="section-head"><div><span class="eyebrow">Follow-ups</span><h2>Marketing</h2><p>Stay on top of customer conversations and opportunities.</p></div></div><div class="list"><div class="list-row"><div class="priority">!</div><div><strong>Follow up with Mbare Grocers</strong><small>Check remaining Cooking Oil stock</small></div><button class="ghost">Complete</button></div><div class="list-row"><div class="priority">!</div><div><strong>Contact Sunrise Mini Mart</strong><small>Reorder discussion</small></div><button class="ghost">Complete</button></div></div>`;
  return `<div class="section-head"><div><span class="eyebrow">Attention</span><h2>Alerts</h2><p>Signals that need your attention.</p></div></div><div class="list"><div class="list-row"><div class="priority">!</div><div><strong>Reorder signal</strong><small>Mbare Grocers may need Cooking Oil soon.</small></div><button class="ghost">Review</button></div><div class="list-row"><div class="priority">!</div><div><strong>Follow-up overdue</strong><small>Sunrise Mini Mart has an outstanding follow-up.</small></div><button class="ghost">Review</button></div></div>`;
}

render();
