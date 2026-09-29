const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const {stripTypeScriptTypes} = require('node:module');
const root = path.join(process.cwd(), 'physio_clinic_platform/functions/src');
const records = new Map();
let nextId = 0;
const copy = value => value === undefined ? undefined : structuredClone(value);
const ref = (collection, id) => ({
  id, key: `${collection}/${id}`,
  async get() { const data = copy(records.get(this.key)); return {id, exists: data !== undefined, ref: this, data: () => copy(data)}; },
  async set(value) { records.set(this.key, copy(value)); },
  async update(value) {
    if (!records.has(this.key)) throw new Error(`missing ${this.key}`);
    const data = records.get(this.key);
    for (const [k,v] of Object.entries(value)) {
      const keys = k.split('.'); let target = data;
      while (keys.length > 1) target = target[keys.shift()];
      const leaf = keys[0]; target[leaf] = v && v.increment !== undefined ? (target[leaf] || 0) + v.increment : copy(v);
    }
  },
});
function query(collection, filters = [], orders = [], maximum = Infinity) {
  return {
    doc(id = `generated-${++nextId}`) { return ref(collection, id); },
    where(field, op, value) { return query(collection, [...filters, [field,op,value]], orders, maximum); },
    orderBy(field, direction = 'asc') { return query(collection, filters, [...orders, [field,direction]], maximum); },
    limit(n) { return query(collection, filters, orders, n); },
    async get() {
      let entries = [...records].filter(([key]) => key.startsWith(`${collection}/`));
      entries = entries.filter(([,data]) => filters.every(([field,op,v]) => ({'==':()=>data[field]===v, 'in':()=>v.includes(data[field]), '>':()=>data[field]>v, '>=':()=>data[field]>=v, '<':()=>data[field]<v, '<=':()=>data[field]<=v})[op]()));
      entries.sort((a,b) => { for (const [field,dir] of orders) { if (a[1][field] !== b[1][field]) return (a[1][field] > b[1][field] ? 1 : -1) * (dir === 'desc' ? -1 : 1); } return 0; });
      const docs = await Promise.all(entries.slice(0,maximum).map(([key]) => ref(collection, key.slice(collection.length + 1)).get()));
      return {docs, size: docs.length, empty: docs.length === 0};
    },
  };
}
function batch() { const ops = []; return {set(r,v) {ops.push(()=>r.set(v));}, update(r,v) {ops.push(()=>r.update(v));}, async commit() {for (const op of ops) await op();}}; }
const db = {collection: query, batch, getAll: (...refs)=>Promise.all(refs.map(r=>r.get())), async runTransaction(fn) { const b = batch(); await fn({...b, get:r=>r.get()}); await b.commit(); }};
let initialized = false;
let messagingFailure = false;
const firestore = Object.assign(() => {if (!initialized) throw new Error('NO_DEFAULT_APP'); return db;}, {Timestamp: {now:()=>({seconds:0})}, FieldValue: {increment: n=>({increment:n}), arrayRemove: (...values)=>({arrayRemove:values})}});
const admin = {initializeApp:()=>{initialized=true;}, firestore, messaging:()=>({sendEachForMulticast:async()=>{if(messagingFailure) throw new Error('FCM_UNAVAILABLE'); return {responses:[],failureCount:0,successCount:0};}})};
class HttpsError extends Error { constructor(code,message) {super(message); this.code=code;} }
let cache = new Map();
function load(filename, from=root) {
  if (filename === 'firebase-admin') return admin;
  if (filename === 'firebase-functions/v2/https') return {HttpsError,onCall:fn=>fn};
  if (filename === 'firebase-functions/v2/scheduler') return {onSchedule:(_,fn)=>fn};
  if (filename === 'firebase-functions') return {setGlobalOptions:()=>{}};
  let absolute = path.resolve(from, filename);
  if (!absolute.endsWith('.ts')) absolute = fs.existsSync(absolute + '.ts') ? absolute + '.ts' : path.join(absolute, 'index.ts');
  if (cache.has(absolute)) return cache.get(absolute);
  let source = stripTypeScriptTypes(fs.readFileSync(absolute,'utf8'));
  const exports = [...source.matchAll(/export\s+(?:async\s+)?(?:function|const)\s+(\w+)/g)].map(m=>m[1]);
  source = source.replace(/import\s+\*\s+as\s+(\w+)\s+from\s+["']([^"']+)["'];/g, (_,name,id)=>`const ${name} = __load(${JSON.stringify(id)});`)
    .replace(/import\s+\{([^}]+)\}\s+from\s+["']([^"']+)["'];/g, (_,names,id)=>`const {${names}} = __load(${JSON.stringify(id)});`)
    .replace(/export\s+(?=(?:async\s+)?(?:function|const))/g,'');
  const context = {__load:id=>load(id,path.dirname(absolute)), console, Date, Set, Map, __exports:{}};
  vm.runInNewContext(source + '\nObject.assign(__exports, {' + exports.join(',') + '});', context, {filename:absolute});
  cache.set(absolute, context.__exports);
  return context.__exports;
}
function seed(clinic='A', days=true) {
  records.clear(); nextId=0; messagingFailure=false;
  records.set('users/adminA',{clinicId:'A',role:'admin'});
  records.set('users/patient',{clinicId:clinic,role:'patient'});
  records.set('therapistAvailability/therapist',{clinicId:clinic,weeklySchedule:days?Object.fromEntries(['mon','tue','wed','thu','fri','sat','sun'].map(d=>[d,['am']])):{}});
  records.set('treatmentPlans/plan',{clinicId:clinic,patientId:'patient',therapistId:'therapist',totalSessions:2,completedSessions:0,cancelledSessions:0,noShowCount:0,remainingNoShows:0,status:'active',scheduleRule:{day1:'2030-01-07',days:['mon','tue','wed','thu','fri','sat','sun'],slotId:'am',frequency:'daily'}});
  records.set('sessions/original',{clinicId:clinic,planId:'plan',patientId:'patient',therapistId:'therapist',sessionNo:1,date:'2030-01-07',slotId:'am',status:'scheduled'});
}
(async()=>{
  try { load('./index'); assert.fail('expected eager initialization error'); } catch(e) {assert.equal(e.message,'NO_DEFAULT_APP'); console.log('Import-order probe: firestore requested before initializeApp. Adapter models documented SDK precondition; actual SDK not installed.');}
  cache = new Map(); initialized=true;
  const index = load('./index'); const reschedule = load('./scheduling/rescheduleService'); const available = load('./scheduling/availabilityService'); const cancel = load('./scheduling/cancellationService');
  seed();
  await reschedule.rescheduleSession('original','2030-01-08','am','A');
  const oldSlot = await available.checkAvailability('A','therapist','2030-01-07','am');
  assert.equal(oldSlot.available,false);
  await reschedule.rescheduleSession('original','2030-01-09','am','A');
  const active = [...records].filter(([key,v])=>key.startsWith('sessions/')&&['scheduled','rescheduled'].includes(v.status));
  assert.equal(active.length,3);
  console.log('Reschedule: original slot remains booked; moving the original twice leaves 3 records treated as active.');
  seed();
  const request = {auth:{uid:'adminA'},data:{sessionId:'original',status:'completed',clinicId:'A'}};
  await index.markSession(request); await index.markSession(request);
  assert.equal(records.get('treatmentPlans/plan').completedSessions,2);
  assert.equal(records.get('treatmentPlans/plan').status,'completed');
  console.log('Duplicate completion: same session marked twice produces completedSessions=2 and completes a 2-session plan.');
  seed('B');
  await index.markSession(request);
  assert.equal(records.get('sessions/original').status,'completed');
  console.log('Object authorization: admin of clinic A successfully marks clinic B session complete using clinicId=A.');
  seed('A',false);
  await assert.rejects(cancel.cancelSession('original','reason','adminA','A'),/Could only find/);
  assert.equal(records.get('sessions/original').status,'cancelled');
  assert.equal(records.get('treatmentPlans/plan').cancelledSessions,1);
  assert.equal([...records.keys()].filter(key=>key.startsWith('sessions/')).length,1);
  console.log('Failed cancellation extension: command rejects but original remains cancelled and counter incremented, with no replacement.');
  seed();
  records.get('treatmentPlans/plan').scheduleRule.day1='2020-01-06';
  await index.markSession({...request,data:{...request.data,status:'no_show'}});
  const replacements = [...records].filter(([key])=>key.startsWith('sessions/')&&key!=='sessions/original');
  assert.equal(replacements[0][1].date,'2020-01-06');
  assert.equal(records.get('treatmentPlans/plan').remainingNoShows,-1);
  console.log('No-show with zero allowance/no active dates: remainingNoShows=-1 and replacement generated on historical plan start 2020-01-06.');
  seed();
  records.get('users/patient').fcmTokens=['token']; messagingFailure=true;
  await assert.rejects(index.markSession(request),/FCM_UNAVAILABLE/);
  assert.equal(records.get('sessions/original').status,'completed');
  assert.equal(records.get('treatmentPlans/plan').completedSessions,1);
  console.log('Notification failure: command rejects with FCM_UNAVAILABLE after session and counters commit.');
  seed();
  records.delete('sessions/original');
  const booking = {auth:{uid:'adminA'},data:{clinicId:'A',patientId:'patient',therapistId:'therapist',totalSessions:1,remainingNoShows:2,idempotencyKey:'same-retry-key',scheduleRule:{day1:'2030-01-07',days:['mon'],slotId:'am',frequency:'once'}}};
  const bookings = await Promise.all([index.createPlan(booking),index.createPlan(booking)]);
  assert.notEqual(bookings[0].planId,bookings[1].planId);
  assert.equal([...records].filter(([key,v])=>key.startsWith('sessions/')&&v.date==='2030-01-07').length,2);
  console.log('Concurrent creation: identical idempotency key creates two plans and double-books the same therapist/date/slot.');
  seed(); records.get('treatmentPlans/plan').totalSessions=1;
  const days=['mon','tue','wed','thu','fri','sat','sun'];
  await reschedule.fullReschedule('plan','2030-01-08',days,'am','A');
  await reschedule.fullReschedule('plan','2030-01-08',days,'am','A');
  assert.equal([...records].filter(([key,v])=>key.startsWith('sessions/')&&['scheduled','rescheduled'].includes(v.status)).length,4);
  console.log('Repeated full reschedule: one appointment becomes four records treated as active after two moves.');
  console.log('All eight behavioral probes passed. These execute original TypeScript with a fake database; not Firestore/emulator integration tests.');
})().catch(error=>{console.error(error);process.exitCode=1;});
