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
 const [editingClient,setEditingClient]=useState<any>(null);

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
   const result=await supabase.from(table).select('*').order('created_at',{ascending:false}).limit(100);
   if(result.error){setRows([]);setActionMessage(result.error.message)}
   else setRows(result.data||[]);
  }else setRows([]);
 }

 async function signIn(){setBusy(true);setMessage('');const {data,error}=await supabase.auth.signInWithPassword({email,password});if(error)setMessage(error.message);else setSession(data.session);setBusy(false)}
 async function signUp(){setBusy(true);setMessage('');const {error}=await supabase.auth.signUp({email,password});setMessage(error?error.message:'Check your email to confirm your Wren account.');setBusy(false)}
 async function signOut(){await supabase.auth.signOut();setSession(null)}
 function go(next:Section){setSection(next);setSearch('');setActionMessage('')}
 function openCreate(target:Section){setEditingClient(null);setForm({});setActionMessage('');setModal(target)}
 function openEditClient(row:any){setEditingClient(row);setForm({company_name:row.company_name||'',name:row.name||'',email:row.email||'',phone:row.phone||'',whatsapp:row.whatsapp||'',address:row.address||'',client_type:row.client_type||'',notes:row.notes||''});setActionMessage('');setModal('Clients')}
 async function createRecord(){
  if(!session||!modal)return;
  setBusy(true);setActionMessage('');
  let payload:any={owner_id:session.user.id};
  if(modal==='Clients') payload={...payload,name:form.name?.trim(),company_name:form.company_name?.trim(),email:form.email?.trim()||null,phone:form.phone?.trim()||null,whatsapp:form.whatsapp?.trim()||null,address:form.address?.trim()||null,client_type:form.client_type?.trim()||null,notes:form.notes?.trim()||null};
  if(modal==='Products') payload={...payload,name:form.name?.trim(),sku:form.sku?.trim()||null,category:form.category?.trim()||null,selling_price:form.selling_price?Number(form.selling_price):null,active:true};
  if(modal==='Marketing') payload={...payload,name:form.name?.trim(),objective:form.objective?.trim()||null,budget:form.budget?Number(form.budget):null,status:'draft'};
  if(modal==='Orders') payload={...payload,client_id:form.client_id?.trim(),total_amount:form.total_amount?Number(form.total_amount):0,notes:form.notes?.trim()||null,status:'draft'};
  const table=tableFor[modal];
  if(modal==='Clients' && !payload.company_name){setActionMessage('Please enter a company name.');setBusy(false);return}
  if(modal==='Clients' && !payload.name){setActionMessage('Please enter the contact person.');setBusy(false);return}
  if(!table||(!payload.name&&!payload.client_id&&!payload.company_name)){setActionMessage(modal==='Orders'?'Enter the client ID.':'Please enter a name.');setBusy(false);return}
  const result=editingClient&&modal==='Clients' ? await supabase.from(table).update(payload).eq('id',editingClient.id) : await supabase.from(table).insert(payload);
  const {error}=result;
  if(error)setActionMessage(error.message);else{setModal(null);setForm({});setEditingClient(null);await loadData()}
  setBusy(false);
 }

 async function handleRowAction(title:Section,row:any,action:string){
  if(!session||!row?.id)return;
  setBusy(true);setActionMessage('');
  let table=tableFor[title];
  let patch:any={};
  if(title==='Clients'&&action==='toggle') patch={status:row.status==='inactive'?'active':'inactive'};
  if(title==='Clients'&&action==='delete'){const {error}=await supabase.from('clients').delete().eq('id',row.id);if(error)setActionMessage(error.message);else{setActionMessage('Client deleted.');await loadData()}setBusy(false);return}
  if(title==='Products'&&action==='toggle') patch={active:!row.active};
  if(title==='Orders'&&action==='advance'){
   const next:Record<string,string>={draft:'confirmed',confirmed:'fulfilled',fulfilled:'completed',completed:'completed',cancelled:'cancelled'};
   patch={status:next[row.status]||'confirmed'};
  }
  if(title==='Marketing'&&action==='toggle'){
   const next=row.status==='active'?'paused':row.status==='paused'?'active':'active';
   patch={status:next};
  }
  if(title==='Alerts'&&action==='read') patch={read_at:new Date().toISOString()};
  if(title==='Alerts'&&action==='dismiss') patch={dismissed_at:new Date().toISOString()};
  if(title==='Intelligence'&&action==='accept') patch={status:'accepted'};
  if(title==='Intelligence'&&action==='reject') patch={status:'rejected'};
  if(!table||Object.keys(patch).length===0){setBusy(false);return}
  const {error}=await supabase.from(table).update(patch).eq('id',row.id);
  if(error)setActionMessage(error.message);else{setActionMessage('Saved.');await loadData()}
  setBusy(false);
 }
 
 const filtered=useMemo(()=>rows.filter(r=>JSON.stringify(r).toLowerCase().includes(search.toLowerCase())),[rows,search]);

 if(!session)return <main className="auth"><div className="authGlow"/><div className="authBrand"><div className="logo">wren<span>•</span></div><div className="kicker">SALES + MARKETING INTELLIGENCE</div><h1>Run the business.<br/><em>See what comes next.</em></h1><p>Wren connects clients, products, orders, marketing activity and business signals in one focused workspace.</p><div className="chips"><span>Clients</span><span>Products</span><span>Orders</span><span>Intelligence</span></div></div><div className="authCard"><div className="eyebrow">WELCOME TO WREN</div><h2>Sign in</h2><p>Access your operational workspace.</p><input placeholder="Email address" type="email" value={email} onChange={e=>setEmail(e.target.value)}/><input placeholder="Password" type="password" value={password} onChange={e=>setPassword(e.target.value)}/>{message&&<div className="notice">{message}</div>}<button className="primary" disabled={busy} onClick={signIn}>{busy?'Signing in…':'Sign in to Wren'}</button><button className="ghost" disabled={busy} onClick={signUp}>Create an account</button></div></main>;

 return <div className="app"><aside><div className="brand"><div className="logo">wren<span>•</span></div><small>WORKSPACE</small></div><nav>{nav.map(([n,icon])=><button key={n} className={section===n?'active':''} onClick={()=>go(n)}><b>{icon}</b>{n}{n==='Alerts'&&<i>{rows.length||3}</i>}</button>)}</nav><div className="sideFoot"><div className="status"><span/>System operational</div><button onClick={signOut}>Sign out</button></div></aside><main className="main"><header><div><div className="crumb">WREN / {section.toUpperCase()}</div><h1>{section}</h1></div><div className="profile"><div className="avatar">{(session.user.email||'W')[0].toUpperCase()}</div><div><strong>{session.user.email}</strong><small>Workspace owner</small></div></div></header>{section==='Dashboard'?<Dashboard counts={counts} setSection={go}/>:<Workspace title={section} rows={filtered} search={search} setSearch={setSearch} actionMessage={actionMessage} counts={counts} onCreate={openCreate} onAction={setActionMessage} onRefresh={loadData} onRowAction={handleRowAction} onEditClient={openEditClient}/>} {modal&&<CreateModal title={modal} form={form} setForm={setForm} busy={busy} message={actionMessage} editing={!!editingClient} onClose={()=>{setModal(null);setEditingClient(null)}} onSave={createRecord}/>} </main></div>;
}

function Dashboard({counts,setSection}:{counts:any;setSection:(s:Section)=>void}){
 return <div className="content"><section className="hero"><div><div className="eyebrow">GOOD MORNING</div><h2>Your business, at a glance.</h2><p>Wren turns day-to-day activity into a clear operational picture.</p></div><div className="heroMark">W</div></section><div className="metrics"><Metric label="Clients" value={counts.clients} icon="♙"/><Metric label="Products" value={counts.products} icon="▦"/><Metric label="Orders" value={counts.orders} icon="↗"/><Metric label="Open signals" value="3" icon="!"/></div><div className="grid2"><section className="panel"><div className="panelHead"><div><span className="eyebrow">PRIORITY</span><h3>What needs attention</h3></div><button className="link" onClick={()=>setSection('Alerts')}>View alerts →</button></div><div className="signal"><span className="dot red"/><div><strong>Reorder opportunity</strong><p>Review clients approaching their expected reorder window.</p></div><b>3</b></div><div className="signal"><span className="dot gold"/><div><strong>Marketing follow-up</strong><p>Reconnect with recent contacts and record the outcome.</p></div><b>7</b></div></section><section className="panel dark"><span className="eyebrow">WREN INTELLIGENCE</span><h3>From activity to action.</h3><p>Wren is designed to connect historical behaviour, current operations and future opportunities.</p><button onClick={()=>setSection('Intelligence')}>Open intelligence →</button></section></div></div>
}

function Metric({label,value,icon}:{label:string;value:any;icon:string}){return <div className="metric"><div className="metricIcon">{icon}</div><div><span>{label}</span><strong>{value}</strong></div></div>}

function Workspace({title,rows,search,setSearch,counts,onCreate,onAction,onRefresh,onRowAction,onEditClient}:{title:Section;rows:any[];search:string;setSearch:(s:string)=>void;counts:any;actionMessage:string;onCreate:(s:Section)=>void;onAction:(s:string)=>void;onRefresh:()=>Promise<void>;onRowAction:(title:Section,row:any,action:string)=>Promise<void>;onEditClient:(row:any)=>void}){
 const copy:Record<string,string>={Clients:'Know who you serve, what they buy and where the next opportunity sits.',Products:'Keep the catalogue clean, commercial and ready for the next order.',Orders:'Capture every order cleanly and keep fulfilment moving.',Marketing:'Turn client activity into deliberate, measurable follow-up.',Alerts:'Signals are organised by urgency so action can happen quickly.',Intelligence:'Use operational evidence to understand what needs attention next.'};
 const canCreate=title==='Clients'||title==='Products'||title==='Marketing'||title==='Orders';
 const createLabel=title==='Clients'?'Add client':title==='Products'?'Add product':title==='Marketing'?'Create campaign':'Create order';
 const actions=(r:any)=>{
  if(title==='Clients')return [{label:r.status==='inactive'?'Activate':'Deactivate',action:'toggle'}];
  if(title==='Products')return [{label:r.active===false?'Activate':'Deactivate',action:'toggle'}];
  if(title==='Orders')return [{label:r.status==='completed'?'Completed':'Advance status',action:'advance'}];
  if(title==='Marketing')return [{label:r.status==='active'?'Pause':r.status==='paused'?'Resume':'Activate',action:'toggle'}];
  if(title==='Alerts')return [...(!r.read_at?[{label:'Mark read',action:'read'}]:[]),...(!r.dismissed_at?[{label:'Dismiss',action:'dismiss'}]:[])];
  if(title==='Intelligence')return r.status==='open'?[{label:'Accept',action:'accept'},{label:'Reject',action:'reject'}]:[];
  return [];
 };
 return <div className="content"><div className="pageIntro"><div><div className="eyebrow">{title.toUpperCase()}</div><h2>{title}</h2><p>{copy[title]}</p></div><button className="primary small" onClick={()=>canCreate?onCreate(title):onRefresh()}>{canCreate?'+ '+createLabel:'↻ Refresh'}</button></div>{['Clients','Products','Orders'].includes(title)&&<div className="metrics compact"><Metric label="Total" value={title==='Clients'?counts.clients:title==='Products'?counts.products:counts.orders} icon="◈"/><Metric label="Active" value={title==='Clients'?'—':title==='Products'?'—':'—'} icon="✓"/><Metric label="Signals" value="3" icon="!" /></div>}<section className="panel tablePanel"><div className="panelHead"><div><h3>{title} workspace</h3><p>Live data from your Wren workspace.</p></div>{['Clients','Products','Orders','Marketing','Alerts','Intelligence'].includes(title)&&<input className="search" placeholder={'Search '+title.toLowerCase()+'…'} value={search} onChange={e=>setSearch(e.target.value)}/>}</div>{rows.length?<div className="rows">{rows.map((r,i)=><div className="row" key={r.id||i}><div className="rowIcon">{title==='Clients'?'♙':title==='Products'?'▦':title==='Orders'?'↗':title==='Marketing'?'✦':title==='Alerts'?'!':'◉'}</div><div className="rowMain">{title==='Clients'?<><strong>{r.company_name||'Unnamed company'}</strong><span>{r.name||'No contact person'}{r.email?' · '+r.email:''}</span></>:<><strong>{r.name||r.title||r.company_name||r.client_name||r.id||'Record'}</strong><span>{r.email||r.status||r.category||r.message||r.reasoning||r.total_amount||r.objective||'Wren record'}</span></>}</div>{title==='Clients'?<span className={'clientStatus '+(r.status==='inactive'?'inactive':'active')}>{r.status==='inactive'?'Inactive':'Active'}</span>:null}<span className="rowMeta">{r.created_at?new Date(r.created_at).toLocaleDateString():''}</span>{title==='Clients'?<ClientMenu row={r} onEdit={onEditClient} onAction={onRowAction}/>:<div className="rowActions">{actions(r).map(a=><button key={a.action} className="rowAction" disabled={false} onClick={()=>onRowAction(title,r,a.action)}>{a.label}</button>)}</div>}</div>)}</div>:<div className="empty"><div>◌</div><h3>No {title.toLowerCase()} to show yet</h3><p>{canCreate?'Use the button above to create your first record.':'Wren will surface records here as they become available.'}</p></div>}</section></div>
}

function CreateModal({title,form,setForm,busy,message,editing,onClose,onSave}:{title:Section;form:Record<string,string>;setForm:(f:Record<string,string>)=>void;busy:boolean;message:string;editing?:boolean;onClose:()=>void;onSave:()=>void}){
 const set=(key:string,value:string)=>setForm({...form,[key]:value});
 const fields=title==='Clients'
  ?[['company_name','Company name','text'],['name','Contact person','text'],['email','Email','email'],['phone','Phone','tel'],['whatsapp','WhatsApp','tel'],['address','Address','text'],['client_type','Client type','text'],['notes','Notes','text']]
  :title==='Products'
  ?[['name','Product name','text'],['sku','SKU','text'],['category','Category','text'],['selling_price','Selling price','number']]
  :title==='Orders'
  ?[['client_id','Client ID','text'],['total_amount','Order total','number'],['notes','Notes','text']]
  :[['name','Campaign name','text'],['objective','Objective','text'],['budget','Budget','number']];
 return <div className="modalBackdrop" onMouseDown={e=>{if(e.target===e.currentTarget)onClose()}}><div className="modalCard"><div className="modalHead"><div><div className="eyebrow">WREN / {editing?'EDIT':'CREATE'}</div><h2>{editing?'Edit client':title==='Clients'?'New client':title==='Products'?'New product':title==='Orders'?'New order':'New campaign'}</h2></div><button className="modalClose" onClick={onClose}>×</button></div>{fields.map(([key,label,type])=>{key==='client_type'?<select key={key} value={form[key]||''} onChange={e=>set(key,e.target.value)}><option value=''>Select client type</option><option value='wholesaler'>Wholesaler</option><option value='supermarket'>Supermarket</option><option value='suprete'>Suprete</option><option value='tuckshop'>Tuckshop</option><option value='vendor'>Vendor</option><option value='takeaway'>Takeaway</option></select>:<input key={key} placeholder={label} type={type} value={form[key]||''} onChange={e=>set(key,e.target.value)}/>})}{message&&<div className="notice">{message}</div>}<div className="modalActions"><button className="ghost" onClick={onClose} disabled={busy}>Cancel</button><button className="primary" onClick={onSave} disabled={busy}>{busy?'Saving…':'Save'}</button></div></div></div>
}

function ClientMenu({row,onEdit,onAction}:{row:any;onEdit:(row:any)=>void;onAction:(title:Section,row:any,action:string)=>Promise<void>}){ const [open,setOpen]=useState(false); return <div className="clientMenu"><button className="kebab" aria-label="Client options" onClick={()=>setOpen(!open)}>•••</button>{open&&<div className="menuPopover"><button onClick={()=>{onEdit(row);setOpen(false)}}>Edit details</button><button onClick={()=>{onAction('Clients',row,'toggle');setOpen(false)}}>{row.status==='inactive'?'Activate':'Deactivate'}</button><button className="dangerText" onClick={()=>{if(window.confirm('Delete this client? This cannot be undone.')){onAction('Clients',row,'delete');setOpen(false)}}}>Delete client</button></div>}</div>}
