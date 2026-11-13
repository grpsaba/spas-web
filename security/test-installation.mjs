// Run against the standalone emulator only: node security/test-installation.mjs
// No production credentials or third-party Node packages are used.
import assert from 'node:assert/strict';
import {test} from 'node:test';
import {readFile} from 'node:fs/promises';

const project = 'demo-spas-installation';
const root = `http://127.0.0.1:8188/v1/projects/${project}/databases/(default)/documents`;
const token = uid => `${Buffer.from(JSON.stringify({alg: 'none', typ: 'JWT'})).toString('base64url')}.${Buffer.from(JSON.stringify({
  iss: `https://securetoken.google.com/${project}`, aud: project, sub: uid, user_id: uid,
  iat: Math.floor(Date.now() / 1000), exp: Math.floor(Date.now() / 1000) + 3600,
  firebase: {sign_in_provider: 'custom', identities: {}}})).toString('base64url')}.`;
function value(v) {
  if (v === null) return {nullValue: null};
  if (v instanceof Date) return {timestampValue: v.toISOString()};
  if (Array.isArray(v)) return {arrayValue: {values: v.map(value)}};
  if (typeof v === 'object') return {mapValue: {fields: fields(v)}};
  if (typeof v === 'boolean') return {booleanValue: v};
  if (typeof v === 'number') return Number.isInteger(v) ? {integerValue: String(v)} : {doubleValue: v};
  return {stringValue: v};
}
const fields = d => Object.fromEntries(Object.entries(d).map(([k, v]) => [k, value(v)]));
function decode(v) {
  if ('nullValue' in v) return null;
  if ('timestampValue' in v) return new Date(v.timestampValue);
  if ('mapValue' in v) return Object.fromEntries(Object.entries(v.mapValue.fields ?? {}).map(([k, x]) => [k, decode(x)]));
  if ('arrayValue' in v) return (v.arrayValue.values ?? []).map(decode);
  if ('integerValue' in v) return Number(v.integerValue);
  return v.stringValue ?? v.booleanValue ?? v.doubleValue;
}
async function call(path, uid = 'owner', body, method = body ? 'POST' : 'GET') {
  const response = await fetch(`${root}${path}`, {method,
    headers: {'Content-Type': 'application/json', ...(uid ? {Authorization: `Bearer ${uid === 'owner' ? uid : token(uid)}`} : {})},
    ...(body ? {body: JSON.stringify(body)} : {})});
  return {status: response.status, body: await response.json()};
}
function write(path, data, timestamps = []) {
  const ordinary = {...data}; for (const key of timestamps) delete ordinary[key];
  return {update: {name: `${root.replace('http://127.0.0.1:8188/v1/', '')}/${path}`, fields: fields(ordinary)},
    ...(timestamps.length ? {updateTransforms: timestamps.map(fieldPath => ({fieldPath, setToServerValue: 'REQUEST_TIME'}))} : {})};
}
const commit = (uid, writes) => call(':commit', uid, {writes});
async function put(path, data) { const r = await commit('owner', [write(path, data)]); assert.equal(r.status, 200, JSON.stringify(r.body)); }
async function read(path, uid = 'owner') {
  const r = await call(`/${path}`, uid); assert.equal(r.status, 200, JSON.stringify(r.body));
  return decode({mapValue: {fields: r.body.fields}});
}
async function expectCommit(uid, writes, expected = 200) {
  const r = await commit(uid, writes); assert.equal(r.status, expected, JSON.stringify(r.body));
}
const base = (uid = 'sup1') => ({schemaVersion: 1, tenantId: 'ml', departmentId: 'security',
  createdBy: {uid, type: 'supervisor', name: 'Superviseur'}, status: 'draft', revision: 1,
  siteName: 'Site Sotuba', clientName: 'Client', address: 'Sotuba', phone: '76000000', bonNumber: '',
  latitude: 12.6, longitude: -8, contractDate: '2026-11-12T00:00:00.000',
  zone: {codeZone: 'z1', name: 'Zone 1'}, supervisor: {UID: 'sup1'}, supervisor2: null,
  agentCount: 2, roundCount: 1, pointageType: 'jour', agents: [{id: 'a', name: 'Nom libre', type: 'ADS', phone: '76000001'}],
  equipment: [{id: 'e', catalogId: 'Lampe', designation: 'Lampe', quantity: 2}],
  createdAt: new Date(), updatedAt: new Date(), siteId: null, attachments: []});
const event = (uid, message = 'Commentaire') => ({kind: 'comment', message, author: {uid, name: uid}, at: new Date()});
const counterPath = 'installationOrderCounters/global';
const counter = (lastNumber, lastOrderId = '', updatedBy = 'admin') =>
  ({lastNumber, lastOrderId, updatedBy, updatedAt: new Date()});
const numberWrite = (lastNumber, id, uid = 'review') =>
  write(counterPath, counter(lastNumber, id, uid), ['updatedAt']);
function approvalWrites(id, order, number, uid = 'review') {
  return [write(`siteInstallationOrders/${id}`, {...order, status: 'approved',
    bonNumber: String(number), revision: order.revision + 1}, ['updatedAt']), numberWrite(number, id, uid),
    write(`siteInstallationOrders/${id}/events/approval-${order.revision}`, {
      ...event(uid, `Validé · Bon n° ${number}`), kind: 'status', from: order.status, to: 'approved'}, ['at'])];
}
// Web SDK transactions use optimistic document-version preconditions. Exercise
// that protocol against the emulator, with two reads of the same counter version.
async function approveTransaction(uid, id, afterRead) {
  for (let attempt = 0; attempt < 6; attempt++) {
    const snapshot = async path => {
      const r = await call(`/${path}`, uid);
      assert.equal(r.status, 200, JSON.stringify(r.body));
      return {data: decode({mapValue: {fields: r.body.fields}}), updateTime: r.body.updateTime};
    };
    const order = await snapshot(`siteInstallationOrders/${id}`);
    const sequence = await snapshot(counterPath);
    if (attempt === 0) await afterRead();
    const number = sequence.data.lastNumber + 1;
    const writes = approvalWrites(id, order.data, number, uid);
    writes[0].currentDocument = {updateTime: order.updateTime};
    writes[1].currentDocument = {updateTime: sequence.updateTime};
    // The web service writes the counter first, so its version precondition is
    // checked before rules for an order referring to the allocated number.
    const result = await commit(uid, [writes[1], writes[0], writes[2]]);
    if (result.status === 200) return {number, attempts: attempt + 1};
    // Rules may reject a stale increment before the version precondition.
    // The service retries permission-denied only after proving the counter
    // advanced, never when access to the unchanged counter is forbidden.
    if (result.body.error?.status === 'PERMISSION_DENIED') {
      const latest = await snapshot(counterPath);
      assert.ok(latest.data.lastNumber > sequence.data.lastNumber, JSON.stringify(result.body));
      continue;
    }
    assert.ok(['ABORTED', 'FAILED_PRECONDITION'].includes(result.body.error?.status), JSON.stringify(result.body));
  }
  assert.fail('Concurrent approval did not finish after retries');
}
const storageRoot = 'http://127.0.0.1:9298/v0/b/demo-spas-installation.appspot.com/o';
async function upload(uid, path, type = 'image/jpeg') {
  const boundary = 'bmps-boundary';
  const body = `--${boundary}\r\nContent-Type: application/json; charset=utf-8\r\n\r\n${JSON.stringify({name: path, contentType: type})}\r\n--${boundary}\r\nContent-Type: ${type}\r\n\r\nimage-test\r\n--${boundary}--`;
  return fetch(`${storageRoot}?name=${encodeURIComponent(path)}`, {method: 'POST',
    headers: {Authorization: `Bearer ${token(uid)}`, 'X-Goog-Upload-Protocol': 'multipart', 'Content-Type': `multipart/related; boundary=${boundary}`}, body});
}

test('Installation workflow permissions and atomic finalization', async t => {
  const rules = await readFile(new URL('./site-installation.firestore.rules', import.meta.url), 'utf8');
  const loaded = await fetch(`http://127.0.0.1:8188/emulator/v1/projects/${project}:securityRules`, {
    method: 'PUT', headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({rules: {files: [{name: 'firestore.rules', content: rules}]}})});
  assert.equal(loaded.status, 200, await loaded.text());
  const cleared = await fetch(`http://127.0.0.1:8188/emulator/v1/projects/${project}/databases/(default)/documents`, {method: 'DELETE'});
  assert.equal(cleared.status, 200);
  if (process.env.TEST_STORAGE === '1') await fetch(`${storageRoot}/${encodeURIComponent('site-installation-orders/ml/order1/photo.jpg')}`, {
    method: 'DELETE', headers: {Authorization: 'Bearer owner'}});
  const permission = (validation, add = false) => ({name: `p${validation}${add}`, installationAccess: {view: true, add, validation, print: true}});
  await put('Profils/Administrateur', {name: 'Administrateur'});
  await put('Managers/admin', {actif: true, tenantId: 'ml', profil: {name: 'Administrateur'}});
  for (const [uid, profile, tenant = 'ml', departmentIds = ['security']] of [
    ['review', permission(true)], ['writer', permission(false, true)], ['viewer', permission(false)],
    ['outsider', permission(true), 'ci'], ['cleaner', permission(true), 'ml', ['cleaning']]]) {
    await put(`Profils/${profile.name}`, profile);
    await put(`Managers/${uid}`, {actif: true, tenantId: tenant, departmentScope: 'limited', departmentIds, profil: {name: profile.name}});
  }
  // Avoid sharing a profile name between the view-only and review fixtures.
  await put('Supervisors/sup1', {UID: 'sup1', tenantId: 'ml', departmentId: 'security', actif: true});
  await put('Supervisors/sup2', {UID: 'sup2', tenantId: 'ml', departmentId: 'security', actif: true});
  await put('Supervisors/portal', {UID: 'portal', tenantId: 'ml', departmentId: 'security', actif: true, isPortal: true});
  await put('ZoneMembers/chief', {UID: 'chief', tenantId: 'ml', departmentId: 'security', actif: true});
  await put('Zones/z1', {codeZone: 'z1', name: 'Zone 1', tenantId: 'ml'});
  let order;
  await t.test('own offline draft can synchronize; portal users cannot initiate', async () => {
    await expectCommit('sup1', [write('siteInstallationOrders/order1', base(), ['createdAt', 'updatedAt'])]);
    await expectCommit('portal', [write('siteInstallationOrders/portal', base('portal'), ['createdAt', 'updatedAt'])], 403);
    await expectCommit('chief', [write('siteInstallationOrders/chief', base('chief'), ['createdAt', 'updatedAt'])]);
    order = await read('siteInstallationOrders/order1');
  });
  await t.test('visibility respects owner, web permissions, tenant and department', async () => {
    for (const uid of ['sup1', 'review', 'viewer']) assert.equal((await call('/siteInstallationOrders/order1', uid)).status, 200, uid);
    for (const uid of ['sup2', 'outsider', 'cleaner', null]) assert.equal((await call('/siteInstallationOrders/order1', uid)).status, 403, String(uid));
    for (const uid of ['sup1', 'review']) {
      assert.equal((await call('/Zones/z1', uid)).status, 200);
      assert.equal((await call('/Supervisors/sup1', uid)).status, 200);
    }
    assert.equal((await call('/Sites/missing-account', 'review')).status, 404);
    assert.equal((await call('/Sites/missing-account', 'viewer')).status, 403);
    const query = await call(':runQuery', 'sup1', {structuredQuery: {from: [{collectionId: 'siteInstallationOrders'}],
      where: {compositeFilter: {op: 'AND', filters: [
        ['tenantId', 'ml'], ['departmentId', 'security'], ['createdBy.uid', 'sup1']].map(([fieldPath, v]) =>
          ({fieldFilter: {field: {fieldPath}, op: 'EQUAL', value: value(v)}}))}}}});
    assert.equal(query.status, 200, JSON.stringify(query.body));
  });
  await t.test('mobile cannot assign a bon number, approve, finalize, or spoof an author', async () => {
    for (const patch of [{bonNumber: '55'}, {status: 'approved'}, {status: 'finalized', siteId: 'x'}, {createdBy: {uid: 'sup2'}}]) {
      await expectCommit('sup1', [write('siteInstallationOrders/order1', {...order, ...patch, revision: 2}, ['updatedAt'])], 403);
    }
    await expectCommit('sup2', [write('siteInstallationOrders/order1/events/spoof', event('sup1'), ['at'])], 403);
  });
  await t.test('comments and submission persist; stale revisions are rejected', async () => {
    await expectCommit('sup1', [write('siteInstallationOrders/order1/events/comment', event('sup1'), ['at'])]);
    await expectCommit('sup1', [write('siteInstallationOrders/order1', {...order, status: 'submitted', revision: 2}, ['updatedAt'])]);
    await expectCommit('sup1', [write('siteInstallationOrders/order1', {...order, siteName: 'Outdated', revision: 2}, ['updatedAt'])], 403);
    order = await read('siteInstallationOrders/order1');
  });
  await t.test('submission and submitted edits require complete fields, at least one agent and equipment', async () => {
    const incomplete = [
      {siteName: ' '}, {clientName: ''}, {address: ''}, {phone: ''}, {agents: []}, {equipment: []},
      {agents: [{id: 'a', name: 'Nom', type: '', phone: '123'}]},
      {agents: [{id: 'a', name: 'Nom', type: 'ADS', phone: ''}]},
      {equipment: [{id: 'e', designation: '', quantity: 1}]},
      {equipment: [{id: 'e', designation: 'Lampe', quantity: 0}]},
      {zone: null}, {supervisor: null}, {contractDate: null}, {agentCount: 0}, {roundCount: 0},
      {latitude: null, longitude: -8}, {latitude: 91, longitude: 0},
      {supervisor2: {UID: 'sup1'}},
    ];
    for (const [index, patch] of incomplete.entries()) {
      const id = `incomplete-${index}`;
      // Partial drafts are still allowed, including offline synchronization.
      await expectCommit('sup1', [write(`siteInstallationOrders/${id}`, {...base(), ...patch}, ['createdAt', 'updatedAt'])]);
      const draft = await read(`siteInstallationOrders/${id}`);
      await expectCommit('sup1', [write(`siteInstallationOrders/${id}`, {...draft, status: 'submitted', revision: 2}, ['updatedAt'])], 403);
      await expectCommit('sup1', [write(`siteInstallationOrders/${id}-direct`, {...base(), ...patch, status: 'submitted'}, ['createdAt', 'updatedAt'])], 403);
      await expectCommit('review', [write('siteInstallationOrders/order1', {...order, ...patch, revision: order.revision + 1}, ['updatedAt'])], 403);
    }
  });
  await t.test('equipment catalogue is shared across companies and legacy entries remain readable', async () => {
    await put('categorieTools/Legacy', {label: 'Legacy', department: {label: 'Sécurité', active: true}});
    await put('categorieTools/Shared', {label: 'Shared', tenantId: 'ci', departmentId: 'security'});
    for (const uid of ['sup1', 'chief', 'review', 'outsider']) {
      const result = await call(':runQuery', uid, {structuredQuery: {from: [{collectionId: 'categorieTools'}]}});
      assert.equal(result.status, 200, JSON.stringify(result.body));
      assert.ok(result.body.some(row => row.document?.name.endsWith('/Legacy')));
      assert.ok(result.body.some(row => row.document?.name.endsWith('/Shared')));
    }
    for (const uid of ['portal', null]) {
      assert.equal((await call(':runQuery', uid, {structuredQuery: {from: [{collectionId: 'categorieTools'}]}})).status, 403);
    }
    const entry = {label: 'New', tenantId: 'ml', departmentId: 'security', department: {id: 'security', label: 'Sécurité', active: true}};
    await expectCommit('sup1', [write('categorieTools/New', entry)]);
    await expectCommit('sup1', [write('categorieTools/Shared', {...entry, label: 'Shared'})], 403);
  });
  await t.test('responsible user corrects or returns for correction', async () => {
    await expectCommit('review', [write('siteInstallationOrders/order1', {...order, phone: '123', revision: 3}, ['updatedAt'])]);
    order = await read('siteInstallationOrders/order1');
    await expectCommit('viewer', [write('siteInstallationOrders/order1', {...order, status: 'changesRequested', revision: 4}, ['updatedAt'])], 403);
    await expectCommit('review', [write('siteInstallationOrders/order1', {...order, status: 'changesRequested', revision: 4}, ['updatedAt']),
      write('siteInstallationOrders/order1/events/return', event('review', 'Préciser le contact'), ['at'])]);
    order = await read('siteInstallationOrders/order1');
    await expectCommit('sup1', [write('siteInstallationOrders/order1', {...order, phone: '12345', status: 'submitted', revision: 5}, ['updatedAt'])]);
    order = await read('siteInstallationOrders/order1');
  });
  await t.test('numbering requires one-time administrator initialization; drafts never consume a number', async () => {
    await expectCommit('review', [write('siteInstallationOrders/order1', {...order, status: 'approved', bonNumber: '31503', revision: order.revision + 1}, ['updatedAt'])], 403);
    for (const uid of ['review', 'writer', 'viewer', 'sup1']) {
      await expectCommit(uid, [numberWrite(31502, '', uid)], 403);
    }
    for (const number of [-1, 1.5, '31502', 9007199254740992]) {
      await expectCommit('admin', [numberWrite(number, '', 'admin')], 403);
    }
    await expectCommit('admin', [numberWrite(31502, '', 'admin')]);
    assert.equal((await call(`/${counterPath}`, 'review')).status, 200);
    for (const uid of ['writer', 'viewer', 'sup1', null]) {
      assert.equal((await call(`/${counterPath}`, uid)).status, 403);
    }
    await expectCommit('admin', [numberWrite(31502, '', 'admin')], 403);
    await expectCommit('admin', [{delete: `${root.replace('http://127.0.0.1:8188/v1/', '')}/${counterPath}`}], 403);
    await expectCommit('writer', [write('siteInstallationOrders/webdraft', base('writer'), ['createdAt', 'updatedAt'])]);
    assert.equal((await read(counterPath)).lastNumber, 31502);
    await expectCommit('admin', [write('siteInstallationOrders/numbered-draft', {...base('admin'), bonNumber: '31503'}, ['createdAt', 'updatedAt'])], 403);
  });
  await t.test('allocation and approval are atomic; manual numbering and skipped numbers are forbidden', async () => {
    await expectCommit('review', [write('siteInstallationOrders/order1', {...order, bonNumber: '31503', revision: order.revision + 1}, ['updatedAt'])], 403);
    const writes = approvalWrites('order1', order, 31503);
    await expectCommit('review', [writes[0]], 403);
    await expectCommit('review', [writes[1]], 403);
    await expectCommit('sup1', approvalWrites('order1', order, 31503, 'sup1'), 403);
    await expectCommit('viewer', approvalWrites('order1', order, 31503, 'viewer'), 403);
    await expectCommit('outsider', approvalWrites('order1', order, 31503, 'outsider'), 403);
    await expectCommit('review', approvalWrites('order1', order, 31504), 403);
    await expectCommit('review', [writes[0], numberWrite(31503, 'chief')], 403);
    // An invalid approval rolls back the counter too.
    await expectCommit('review', approvalWrites('order1', {...order, agentCount: 0}, 31503), 403);
    assert.equal((await read(counterPath)).lastNumber, 31502);
    assert.equal((await read('siteInstallationOrders/order1')).bonNumber, '');
    await expectCommit('review', writes);
    order = await read('siteInstallationOrders/order1');
    assert.equal(order.bonNumber, '31503');
    assert.equal((await read(counterPath)).lastNumber, 31503);
    await expectCommit('review', writes, 403);
  });
  await t.test('corrections and reapproval preserve the assigned number without another increment', async () => {
    await expectCommit('review', [write('siteInstallationOrders/order1', {...order, status: 'changesRequested', revision: order.revision + 1}, ['updatedAt'])]);
    order = await read('siteInstallationOrders/order1');
    for (const uid of ['sup1', 'review', 'admin']) {
      await expectCommit(uid, [write('siteInstallationOrders/order1', {...order, bonNumber: '99', revision: order.revision + 1}, ['updatedAt'])], 403);
    }
    await expectCommit('sup1', [write('siteInstallationOrders/order1', {...order, status: 'submitted', phone: '6789', revision: order.revision + 1}, ['updatedAt'])]);
    order = await read('siteInstallationOrders/order1');
    await expectCommit('review', approvalWrites('order1', order, 31504), 403);
    await expectCommit('review', [write('siteInstallationOrders/order1', {...order, status: 'approved', revision: order.revision + 1}, ['updatedAt'])]);
    order = await read('siteInstallationOrders/order1');
    assert.equal(order.bonNumber, '31503');
    assert.equal((await read(counterPath)).lastNumber, 31503);
  });
  await t.test('approval, physical handover and signed return require the responsible user', async () => {
    for (const status of ['awaitingSignature', 'signedReturned']) {
      await expectCommit('sup1', [write('siteInstallationOrders/order1', {...order, status, revision: order.revision + 1}, ['updatedAt'])], 403);
      await expectCommit('review', [write('siteInstallationOrders/order1', {...order, status, revision: order.revision + 1}, ['updatedAt'])]);
      order = await read('siteInstallationOrders/order1');
    }
  });
  await t.test('simultaneous approvals across companies share one sequence and retry conflicts', async () => {
    await put('siteInstallationOrders/race1', {...base(), status: 'submitted'});
    await put('siteInstallationOrders/race2', {...base(), tenantId: 'ci', status: 'submitted'});
    let ready = 0;
    let release;
    const barrier = new Promise(resolve => { release = resolve; });
    const afterRead = async () => { if (++ready === 2) release(); await barrier; };
    const results = await Promise.all([
      approveTransaction('review', 'race1', afterRead),
      approveTransaction('outsider', 'race2', afterRead),
    ]);
    assert.deepEqual(results.map(r => r.number).sort(), [31504, 31505]);
    assert.ok(results.some(r => r.attempts > 1), 'The contending transaction should retry');
    assert.equal((await read(counterPath)).lastNumber, 31505);
    const one = await read('siteInstallationOrders/race1');
    const two = await read('siteInstallationOrders/race2');
    assert.notEqual(one.bonNumber, two.bonNumber);
    // One counter increment cannot number two orders in a single batch.
    await put('siteInstallationOrders/race3', {...base(), status: 'submitted'});
    await put('siteInstallationOrders/race4', {...base(), status: 'submitted'});
    const three = await read('siteInstallationOrders/race3');
    const four = await read('siteInstallationOrders/race4');
    await expectCommit('review', [...approvalWrites('race3', three, 31506), approvalWrites('race4', four, 31506)[0]], 403);
    assert.equal((await read(counterPath)).lastNumber, 31505);
  });
  await t.test('signed upload tickets are restricted to participants and expire', async () => {
    const ticket = {uid: 'sup1', tenantId: 'ml', path: 'site-installation-orders/ml/order1/photo.jpg', contentType: 'image/jpeg',
      at: new Date(), expiresAt: new Date(Date.now() + 15 * 60 * 1000)};
    await expectCommit('sup1', [write('siteInstallationOrders/order1/uploads/photo.jpg', ticket, ['at'])]);
    await expectCommit('sup2', [write('siteInstallationOrders/order1/uploads/other.jpg', {...ticket, uid: 'sup2', path: 'site-installation-orders/ml/order1/other.jpg'}, ['at'])], 403);
    await expectCommit('sup1', [write('siteInstallationOrders/order1/uploads/late.jpg', {...ticket, path: 'site-installation-orders/ml/order1/late.jpg', expiresAt: new Date(Date.now() + 86400000)}, ['at'])], 403);
  });
  if (process.env.TEST_STORAGE === '1') await t.test('Storage enforces author, ticket, content type and immutable uploads', async () => {
    const path = 'site-installation-orders/ml/order1/photo.jpg';
    for (const [uid, name, type] of [['sup2', path, 'image/jpeg'], ['sup1', path, 'application/pdf'], ['sup1', `${path}-missing`, 'image/jpeg']]) {
      const r = await upload(uid, name, type); assert.equal(r.status, 403, await r.text());
    }
    const r = await upload('sup1', path); assert.equal(r.status, 200, await r.text());
    const overwrite = await upload('sup1', path); assert.equal(overwrite.status, 403, await overwrite.text());
    const metadata = await fetch(`${storageRoot}/${encodeURIComponent(path)}`, {headers: {Authorization: `Bearer ${token('sup1')}`}});
    assert.equal(metadata.status, 200, await metadata.text());
  });
  await t.test('only the responsible user can create the active site, atomically with finalization', async () => {
    const final = {...order, status: 'finalized', siteId: 'site1', revision: order.revision + 1, finalizedBy: 'review', finalizedAt: new Date()};
    const site = {UID: 'site1', installationOrderId: 'order1', actif: true, tenantId: 'ml', departmentIds: ['security'],
      name: order.siteName, adresse: order.address, nbAgent: order.agentCount, nbRonde: order.roundCount, dateContrat: order.contractDate,
      pointageType: 'jour', latLng: {lat: order.latitude, lng: order.longitude}, zone: await read('Zones/z1'),
      supervisor: await read('Supervisors/sup1'), supervisor_2: null};
    const writes = [write('siteInstallationOrders/order1', final, ['updatedAt', 'finalizedAt']), write('Sites/site1', site)];
    await expectCommit('review', [writes[0]], 403);
    await expectCommit('review', [writes[1]], 403);
    await expectCommit('sup1', writes, 403);
    await expectCommit('viewer', writes, 403);
    await expectCommit('outsider', writes, 403);
    await expectCommit('review', writes);
    assert.equal((await read('Sites/site1')).actif, true);
    assert.equal((await read('siteInstallationOrders/order1')).siteId, 'site1');
    await expectCommit('review', writes, 403);
    await expectCommit('review', [write('Sites/site2', {...site, UID: 'site2'})], 403);
    if (process.env.TEST_STORAGE === '1') {
      const r = await fetch(`${storageRoot}/${encodeURIComponent('site-installation-orders/ml/order1/photo.jpg')}`, {
        method: 'DELETE', headers: {Authorization: `Bearer ${token('sup1')}`}});
      assert.equal(r.status, 403, await r.text());
    }
  });
  await t.test('orders without GPS or second supervisor can be submitted, approved and finalized', async () => {
    const id = 'no-gps';
    await expectCommit('sup1', [write(`siteInstallationOrders/${id}`, {...base(), latitude: null, longitude: null, status: 'submitted'}, ['createdAt', 'updatedAt'])]);
    let current = await read(`siteInstallationOrders/${id}`);
    await expectCommit('review', approvalWrites(id, current, (await read(counterPath)).lastNumber + 1));
    for (const status of ['awaitingSignature', 'signedReturned']) {
      current = await read(`siteInstallationOrders/${id}`);
      await expectCommit('review', [write(`siteInstallationOrders/${id}`, {...current, status, revision: current.revision + 1}, ['updatedAt'])]);
    }
    current = await read(`siteInstallationOrders/${id}`);
    const final = {...current, status: 'finalized', siteId: 'no-gps-site', revision: current.revision + 1, finalizedBy: 'review', finalizedAt: new Date()};
    const site = {UID: 'no-gps-site', installationOrderId: id, actif: true, tenantId: 'ml', departmentIds: ['security'],
      name: current.siteName, adresse: current.address, nbAgent: current.agentCount, nbRonde: current.roundCount, dateContrat: current.contractDate,
      pointageType: 'jour', latLng: null, zone: await read('Zones/z1'), supervisor: await read('Supervisors/sup1'), supervisor_2: null};
    await expectCommit('review', [write(`siteInstallationOrders/${id}`, final, ['updatedAt', 'finalizedAt']), write('Sites/no-gps-site', site)]);
    assert.equal((await read('Sites/no-gps-site')).latLng, null);
  });
});
