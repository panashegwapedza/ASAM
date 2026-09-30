'use client';
import { useEffect,useMemo,useState } from 'react';
import { createClient, type SupabaseClient } from '@supabase/supabase-js';

const supabaseUrl=process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://uckwrngfdibugwrhvagl.supabase.co';
const supabaseKey=process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'sb_publishable_Cp62FhbYisA0Pmjxw-Iw1g_YFLnGPPt';
const supabase:SupabaseClient=createClient(supabaseUrl,supabaseKey);

type Section='Dashboard'|'Clients'|'Products'|'Orders'|'Marketing'|'Alerts'|'Intelligence';
const nav:[Section,string][]=[['Dashboard','◈'],['Clients','♙'],['Products','▦'],['Orders','↗'],['Marketing','✦'],['Alerts','!'],['Intelligence','◉']];
const tableFor:Partial<Record<Section,string>>={Clients:'clients',Products:'products',Orders:'orders',Marketing:'campaigns',Alerts:'alerts',Intelligence:'recommendations'};

export default function Home(){
 const [section,setSection]=useState<Section>('Dashboard');
 const [session,setSession]=useState<any>(null);
 const [email,setEmail]=useState(''); const [password,setPassword]=useState('');
 const [busy,setBusy]=useState(false); const [message,setMessage]=useState('');
 const [counts,setCounts]=useState({clients:0,products:0,orders:0});
 const [rows,setRows]=useState<any[]>([]); const [search,setSearch]=useState('');
 const [modal,setModal]=useState<Section|null>(null);
 const [form,setForm]=useState<Record<string,string>>({});
 const [actionMessage,setActionMessage]=useState('');

 useEffect(()=>{supabase.auth.getSession().then(({data})=>setSession(data.session));const {data}=supabase.auth.onAuthStateChange((_e,s)=>setSession(s));return()=>data.subscription.unsubscribe()},[]);
 useEffect(()=>{if(session)loadData()},[session,section]);

 async function loadData(){
  const [c,p,o]=await Promise.all([
   supabase.from('clients').select('*',{count:'exact',head:true}),
   supabase.from('products').select('*',{count:'exact',head:true}),
   supabase.from('orders').select('*',{count:'exact',head:true})
  ]);
  setCounts({clients:c.count||0,products:p.count||0,orders:o.count||0});
  const table=tableFor[section];
  if(table){
   const query=supabase.from(table).select('*').limit(100);
   const result=section==='Orders'?await query.order('created_at',{ascending:false}):await query.order('created_at',{ascending:false});
   setRows(result.data||[]);
  }else setRows([]);
 }

 async function signIn(){setBusy(true);setMessage('');const {data,error}=await supabase.auth.signInWithPassword({email,password});if(error)setMessage(error.message);else setSession(data.session);setBusy(false)}
 async function signUp(){setBusy(true);setMessage('');const {error}=await supabase.auth.signUp({email,password});setMessage(error?error.message:'Check your email to confirm your Wren account.');setBusy(false)}
 async function signOut(){await supabase.auth.signOut();setSession(null)}
 function go(next:Section){setSection(next);setSearch('');setActionMessage('')}
 function openCreate(target:Section){setForm({});setActionMessage('');setModal(target)}
 async function createRecord(){
  if(!session||!modal)return;
  setBusy(true);setActionMessage('');
  let payload:any={owner_id:session.user.id};
  if(modal==='Clients') payload={...payload,name:form.name?.trim(),company_name:form.company_name?.trim()||null,email:form.email?.trim()||null,phone:form.phone?.trim()||null,status:'active'};
  if(modal==='Products') payload={...payload,name:form.name?.trim(),sku:form.sku?.trim()||null,category:form.category?.trim()||null,selling_price:form.selling_price?Number(form.selling_price):null,active:true};
  if(modal==='Marketing') payload={...payload,name:form.name?.trim(),objective:form.objective?.trim()||null,status:'draft'};
  const table=tableFor[modal];
  if(!table||!payload.name){setActionMessage('Please enter a name.');setBusy(false);return}
  const {error}=await supabase.from(table).insert(payload);
  if(error)setActionMessage(error.message);else{setModal(null);setForm({});await loadData()}
  setBusy(false);
 }

 const filtered=useMemo(()=>rows.filter(r=>JSON.stringify(r).toLowerCase().includes(search.toLowerCase())),[rows,search]);

 if(!session)return <main className="auth"><div className="authGlow"/><div className="authBrand"><div className="logo">wren<span>•</span></div><div className="kicker">SALES + MARKETING INTELLIGENCE</div><h1>Run the business.<br/><em>See what comes next.</em></h1><p>Wren connects clients, products, orders, marketing activity and business signals in one focused workspace.</p><div className="chips"><span>Clients</span><span>Products</span><span>Orders</span><span>Intelligence</span></div></div><div className="authCard"><div className="eyebrow">WELCOME TO WREN</div><h2>Sign in</h2><p>Access your operational workspace.</p><input placeholder="Email address" type="email" value={email} onChange={e=>setEmail(e.target.value)}/><input placeholder="Password" type="password" value={password} onChange={e=>setPassword(e.target.value)}/>{message&&<div className="notice">{message}</div>}<button className="primary" disabled={busy} onClick={signIn}>{busy?'Signing in…':'Sign in to Wren'}</button><button className="ghost" disabled={busy} onClick={signUp}>Create an account</button></div></main>;

 return <div className="app"><aside><div className="brand"><div className="logo">wren<span>•</span></div><small>WORKSPACE</small></div><nav>{nav.map(([n,icon])=><button key={n} className={section===n?'active':''} onClick={()=>go(n)}><b>{icon}</b>{n}{n==='Alerts'&&<i>{rows.length||3}</i>}</button>)}</nav><div className="sideFoot"><div className="status"><span/>System operational</div><button onClick={signOut}>Sign out</button></div></aside><main className="main"><header><div><div className="crumb">WREN / {section.toUpperCase()}</div><h1>{section}</h1></div><div className="profile"><div className="avatar">{(session.user.email||'W')[0].toUpperCase()}</div><div><strong>{session.user.email}</strong><small>Workspace owner</small></div></div></header>{section==='Dashboard'?<Dashboard counts={counts} setSection={go}/>:<Workspace title={section} rows={filtered} search={search} setSearch={setSearch} counts={counts} onCreate={openCreate} onAction={setActionMessage}/>} {modal&&<CreateModal title={modal} form={form} setForm={setForm} busy={busy} message={actionMessage} onClose={()=>setModal(null)} onSave={createRecord}/>} </main></div>;
}

function Dashboard({counts,setSection}:{counts:any;setSection:(s:Section)=>void}){
 return <div className="content"><section className="hero"><div><div className="eyebrow">GOOD MORNING</div><h2>Your business, at a glance.</h2><p>Wren turns day-to-day activity into a clear operational picture.</p></div><div className="heroMark">W</div></section><div className="metrics"><Metric label="Clients" value={counts.clients} icon="♙"/><Metric label="Products" value={counts.products} icon="▦"/><Metric label="Orders" value={counts.orders} icon="↗"/><Metric label="Open signals" value="3" icon="!"/></div><div className="grid2"><section className="panel"><div className="panelHead"><div><span className="eyebrow">PRIORITY</span><h3>What needs attention</h3></div><button className="link" onClick={()=>setSection('Alerts')}>View alerts →</button></div><div className="signal"><span className="dot red"/><div><strong>Reorder opportunity</strong><p>Review clients approaching their expected reorder window.</p></div><b>3</b></div><div className="signal"><span className="dot gold"/><div><strong>Marketing follow-up</strong><p>Reconnect with recent contacts and record the outcome.</p></div><b>7</b></div></section><section className="panel dark"><span className="eyebrow">WREN INTELLIGENCE</span><h3>From activity to action.</h3><p>Wren is designed to connect historical behaviour, current operations and future opportunities.</p><button onClick={()=>setSection('Intelligence')}>Open intelligence →</button></section></div></div>
}

function Metric({label,value,icon}:{label:string;value:any;icon:string}){return <div className="metric"><div className="metricIcon">{icon}</div><div><span>{label}</span><strong>{value}</strong></div></div>}

function Workspace({title,rows,search,setSearch,counts,onCreate,onAction}:{title:Section;rows:any[];search:string;setSearch:(s:string)=>void;counts:any;onCreate:(s:Section)=>void;onAction:(s:string)=>void}){
 const copy:Record<string,string>={Clients:'Know who you serve, what they buy and where the next opportunity sits.',Products:'Keep the catalogue clean, commercial and ready for the next order.',Orders:'Capture every order cleanly and keep fulfilment moving.',Marketing:'Turn client activity into deliberate, measurable follow-up.',Alerts:'Signals are organised by urgency so action can happen quickly.',Intelligence:'Use operational evidence to understand what needs attention next.'};
 const canCreate=title==='Clients'||title==='Products'||title==='Marketing';
 const createLabel=title==='Clients'?'Add client':title==='Products'?'Add product':'Create campaign';
 const refresh=()=>{onAction('Refreshing '+title.toLowerCase()+'…');window.location.reload()};
 return <div className="content"><div className="pageIntro"><div><div className="eyebrow">{title.toUpperCase()}</div><h2>{title}</h2><p>{copy[title]}</p></div><button className="primary small" onClick={()=>canCreate?onCreate(title):refresh()}>{canCreate?'+ '+createLabel:'↻ Refresh'}</button></div>{['Clients','Products','Orders'].includes(title)&&<div className="metrics compact"><Metric label="Total" value={title==='Clients'?counts.clients:title==='Products'?counts.products:counts.orders} icon="◈"/><Metric label="Active" value={title==='Clients'?'—':title==='Products'?'—':'—'} icon="✓"/><Metric label="Signals" value="3" icon="!" /></div>}<section className="panel tablePanel"><div className="panelHead"><div><h3>{title} workspace</h3><p>Live data from your Wren workspace.</p></div>{['Clients','Products','Orders','Marketing','Alerts','Intelligence'].includes(title)&&<input className="search" placeholder={'Search '+title.toLowerCase()+'…'} value={search} onChange={e=>setSearch(e.target.value)}/>}</div>{rows.length?<div className="rows">{rows.map((r,i)=><div className="row" key={r.id||i}><div className="rowIcon">{title==='Clients'?'♙':title==='Products'?'▦':title==='Orders'?'↗':title==='Marketing'?'✦':title==='Alerts'?'!':'◉'}</div><div className="rowMain"><strong>{r.name||r.title||r.company_name||r.client_name||r.id||'Record'}</strong><span>{r.email||r.status||r.category||r.message||r.reasoning||r.total_amount||r.objective||'Wren record'}</span></div><span className="rowMeta">{r.created_at?new Date(r.created_at).toLocaleDateString():''}</span><span>→</span></div>)}</div>:<div className="empty"><div>◌</div><h3>No {title.toLowerCase()} to show yet</h3><p>{title==='Clients'||title==='Products'||title==='Marketing'?'Use the button above to create your first record.':'Wren will surface records here as they become available.'}</p></div>}</section></div>
}

function CreateModal({title,form,setForm,busy,message,onClose,onSave}:{title:Section;form:Record<string,string>;setForm:(f:Record<string,string>)=>void;busy:boolean;message:string;onClose:()=>void;onSave:()=>void}){
 const set=(key:string,value:string)=>setForm({...form,[key]:value});
 const fields=title==='Clients'?[['name','Client name','text'],['company_name','Company name','text'],['email','Email','email'],['phone','Phone','tel']]:title==='Products'?[['name','Product name','text'],['sku','SKU','text'],['category','Category','text'],['selling_price','Selling price','number']]:[['name','Campaign name','text'],['objective','Objective','text']];
 return <div className="modalBackdrop" onMouseDown={e=>{if(e.target===e.currentTarget)onClose()}}><div className="modalCard"><div className="modalHead"><div><div className="eyebrow">WREN / CREATE</div><h2>{title==='Clients'?'New client':title==='Products'?'New product':'New campaign'}</h2></div><button className="modalClose" onClick={onClose}>×</button></div>{fields.map(([key,label,type])=><input key={key} placeholder={label} type={type} value={form[key]||''} onChange={e=>set(key,e.target.value)}/>)}{message&&<div className="notice">{message}</div>}<div className="modalActions"><button className="ghost" onClick={onClose} disabled={busy}>Cancel</button><button className="primary" onClick={onSave} disabled={busy}>{busy?'Saving…':'Save '+title.slice(0,-1).toLowerCase()}</button></div></div></div>
}
