#!/usr/bin/env node

/*
 * Backfill departmentId / departmentIds on historical Firestore documents.
 *
 * Safe by design:
 * - dry-run by default;
 * - updates only top-level departmentId / departmentIds;
 * - never rewrites whole documents;
 * - logs ambiguous documents instead of guessing;
 * - defaults to Mali documents: tenantId missing or tenantId == "ml".
 *
 * Usage:
 *   node scripts/backfill_department_fields.js
 *   node scripts/backfill_department_fields.js --execute
 *   node scripts/backfill_department_fields.js --collections Agents,Supervisors
 *   node scripts/backfill_department_fields.js --tenant ml --max-docs 100
 *   node scripts/backfill_department_fields.js --collections Sites --log-skipped
 *   node scripts/backfill_department_fields.js --collections sitePointings --last-days 7 --execute
 *   node scripts/backfill_department_fields.js --collections sitePointings --current-month --execute
 *   node scripts/backfill_department_fields.js --collections sitePointings --date-from 2026-07-01 --date-to 2026-07-08 --execute
 *   node scripts/backfill_department_fields.js --project spas-cd4c9 --execute
 *   node scripts/backfill_department_fields.js --project spas-cd4c9 --credentials C:\path\service-account.json --execute
 *
 * Date filter:
 *   Uses UTC day boundaries. --date-from is inclusive, --date-to is exclusive.
 *   Example: --date-from 2026-07-01 --date-to 2026-07-08 scans July 1 through July 7.
 *
 * Auth:
 *   Use one of:
 *   - gcloud auth application-default login
 *   - set GOOGLE_APPLICATION_CREDENTIALS=C:\path\service-account.json
 */

const admin = require('firebase-admin');
const path = require('path');

const DEFAULT_TENANT_ID = 'ml';
const DEFAULT_DATE_FIELD = 'datetimestamp';

const DEPARTMENTS = {
  security: { id: 'security', label: 'Securite', active: true },
  cleaning: { id: 'cleaning', label: 'Nettoyage', active: true },
  direction: { id: 'direction', label: 'Direction', active: true },
};

const COLLECTION_FORCED_DEPARTMENT_ID = {
  zonePointings: 'security',
  agentPointings: 'direction',
};

const COLLECTION_AMBIGUITY_FALLBACK_DEPARTMENT_ID = {
  Notes: 'security',
  sitePointings: 'security',
};

const SIMPLE_COLLECTIONS = [
  'Agents',
  'Supervisors',
  'ZoneMembers',
  'categorieTools',
  'Tools',
  'Notes',
  'CheckLists',
  'sitePointings',
  'agentPointings',
  'zonePointings',
  'toolPointings',
  'rondierPointings',
  'locationTracker',
  'error_logs',
];

const DEFAULT_COLLECTIONS = ['departments', ...SIMPLE_COLLECTIONS, 'Sites'];
const DATE_FILTERABLE_COLLECTIONS = new Set([
  'sitePointings',
  'zonePointings',
]);

const args = parseArgs(process.argv.slice(2));
const execute = Boolean(args.execute);
const logSkipped = Boolean(args.logSkipped);
const tenantId = normalizeTenantId(args.tenant || DEFAULT_TENANT_ID);
const pageSize = Number(args.pageSize || 1000);
const maxDocs = args.maxDocs ? Number(args.maxDocs) : null;
const projectId = args.project || process.env.GCLOUD_PROJECT || undefined;
const credentialsPath = args.credentials || process.env.GOOGLE_APPLICATION_CREDENTIALS;
const collections = args.collections
  ? args.collections.split(',').map((value) => value.trim()).filter(Boolean)
  : DEFAULT_COLLECTIONS;
const includeMissingTenant = args.includeMissingTenant !== 'false';
const dateField = normalizeDateField(args.dateField || DEFAULT_DATE_FIELD);
const dateRange = buildDateRange(args);

if (!Number.isInteger(pageSize) || pageSize < 1 || pageSize > 1000) {
  fail('--page-size must be an integer between 1 and 1000.');
}

if (maxDocs !== null && (!Number.isInteger(maxDocs) || maxDocs < 1)) {
  fail('--max-docs must be a positive integer.');
}

admin.initializeApp({
  credential: credentialsPath
    ? admin.credential.cert(require(path.resolve(credentialsPath)))
    : admin.credential.applicationDefault(),
  projectId,
});

const db = admin.firestore();
const fieldPathDocumentId = admin.firestore.FieldPath.documentId();
const docCache = new Map();

async function main() {
  const startedAtMs = Date.now();

  console.log('Department backfill');
  console.log(`Mode: ${execute ? 'EXECUTE' : 'DRY-RUN'}`);
  console.log(`Project: ${projectId || '(default credentials project)'}`);
  console.log(`Credentials: ${credentialsPath || '(application default)'}`);
  console.log(`Tenant: ${tenantId}`);
  console.log(`Include missing tenantId: ${includeMissingTenant}`);
  console.log(`Log skipped docs: ${logSkipped}`);
  console.log(`Page size: ${pageSize}`);
  if (maxDocs !== null) console.log(`Max docs per collection: ${maxDocs}`);
  if (dateRange) {
    console.log(
      `Date filter: ${dateField} >= ${dateRange.start.toISOString()} and < ${dateRange.end.toISOString()}`,
    );
    console.log(
      `Date-filtered collections: ${Array.from(DATE_FILTERABLE_COLLECTIONS).join(', ')}`,
    );
  } else {
    console.log('Date filter: none');
  }
  console.log(`Collections: ${collections.join(', ')}`);
  console.log('');

  if (!execute) {
    console.log('Dry-run only. Add --execute to write department fields.');
    console.log('');
  }

  const totals = {
    scanned: 0,
    inScope: 0,
    toUpdate: 0,
    updated: 0,
    skipped: 0,
    ambiguous: 0,
    errors: 0,
  };

  for (const collectionName of collections) {
    const result = collectionName === 'departments'
      ? await backfillDepartments()
      : collectionName === 'Sites'
        ? await backfillCollection(collectionName, buildSiteUpdate)
        : await backfillCollection(collectionName, buildSimpleUpdate);

    addTotals(totals, result);
  }

  console.log('');
  console.log('Summary');
  console.log(`Scanned: ${totals.scanned}`);
  console.log(`In tenant scope: ${totals.inScope}`);
  console.log(`To update: ${totals.toUpdate}`);
  console.log(`Updated: ${totals.updated}`);
  console.log(`Skipped: ${totals.skipped}`);
  console.log(`Ambiguous: ${totals.ambiguous}`);
  console.log(`Errors: ${totals.errors}`);
  console.log(`Duration: ${formatDuration(Date.now() - startedAtMs)}`);

  if (!execute) {
    console.log('');
    console.log('No data was modified. Re-run with --execute to apply changes.');
  }

  if (totals.errors > 0) process.exitCode = 1;
}

async function backfillDepartments() {
  console.log('Collection: departments');

  const stats = emptyStats();
  const writer = execute ? db.bulkWriter() : null;
  configureWriter(writer, stats);

  for (const department of Object.values(DEPARTMENTS)) {
    stats.scanned += 1;
    stats.inScope += 1;

    const ref = db.collection('departments').doc(department.id);
    const snapshot = await ref.get();
    const current = snapshot.exists ? snapshot.data() : {};
    const update = {};

    if (current.id !== department.id) update.id = department.id;
    if (current.label !== department.label) update.label = department.label;
    if (current.active !== department.active) update.active = department.active;

    if (Object.keys(update).length === 0) {
      stats.skipped += 1;
      if (logSkipped) console.log(`  skipped ${ref.path}: already up to date`);
      continue;
    }

    stats.toUpdate += 1;
    console.log(`  ${ref.path} -> ${JSON.stringify(update)}`);

    if (execute) {
      writer.set(ref, { ...department }, { merge: true });
      stats.updated += 1;
    }
  }

  if (writer) await writer.close();
  logDone(stats);
  return stats;
}

async function backfillCollection(collectionName, buildUpdate) {
  console.log(`Collection: ${collectionName}`);

  const stats = emptyStats();
  let lastDoc = null;
  const useDateFilter = shouldUseDateFilter(collectionName);

  if (dateRange && !useDateFilter) {
    console.log(
      `  date filter ignored for ${collectionName}: no configured ${dateField} range support`,
    );
  }

  while (true) {
    let query = buildCollectionQuery(collectionName, useDateFilter);

    if (lastDoc) query = query.startAfter(lastDoc);

    const snapshot = await query.get();
    if (snapshot.empty) break;

    const writer = execute ? db.bulkWriter() : null;
    configureWriter(writer, stats);

    for (const doc of snapshot.docs) {
      if (maxDocs !== null && stats.scanned >= maxDocs) break;

      stats.scanned += 1;
      const data = doc.data();

      if (!isTenantInScope(data)) {
        stats.skipped += 1;
        if (logSkipped) {
          console.log(
            `  skipped ${doc.ref.path}: tenant out of scope (tenantId=${JSON.stringify(data.tenantId)})`,
          );
        }
        continue;
      }

      stats.inScope += 1;
      const result = await buildUpdate(data, collectionName);

      if (result.status === 'skip') {
        stats.skipped += 1;
        if (logSkipped) console.log(`  skipped ${doc.ref.path}: already up to date`);
        continue;
      }

      if (result.status === 'ambiguous') {
        stats.ambiguous += 1;
        console.log(`  ambiguous ${doc.ref.path}: ${result.reason}`);
        continue;
      }

      stats.toUpdate += 1;
      console.log(`  ${doc.ref.path} -> ${JSON.stringify(result.update)}`);

      if (execute) {
        writer.update(doc.ref, result.update);
        stats.updated += 1;
      }
    }

    if (writer) await writer.close();

    lastDoc = snapshot.docs[snapshot.docs.length - 1];

    console.log(
      `  scanned=${stats.scanned} inScope=${stats.inScope} toUpdate=${stats.toUpdate} updated=${stats.updated} skipped=${stats.skipped} ambiguous=${stats.ambiguous}`,
    );

    if (maxDocs !== null && stats.scanned >= maxDocs) break;
    if (snapshot.size < pageSize) break;
  }

  logDone(stats);
  return stats;
}

function buildCollectionQuery(collectionName, useDateFilter) {
  if (!useDateFilter) {
    return db
      .collection(collectionName)
      .orderBy(fieldPathDocumentId)
      .limit(pageSize);
  }

  return db
    .collection(collectionName)
    .where(dateField, '>=', admin.firestore.Timestamp.fromDate(dateRange.start))
    .where(dateField, '<', admin.firestore.Timestamp.fromDate(dateRange.end))
    .orderBy(dateField)
    .orderBy(fieldPathDocumentId)
    .limit(pageSize);
}

function shouldUseDateFilter(collectionName) {
  return Boolean(dateRange && DATE_FILTERABLE_COLLECTIONS.has(collectionName));
}

async function buildSimpleUpdate(data, collectionName) {
  const existing = normalizeDepartmentId(data.departmentId);
  if (existing) {
    if (data.departmentId === existing) return { status: 'skip' };
    return { status: 'update', update: { departmentId: existing } };
  }

  const forcedDepartmentId = COLLECTION_FORCED_DEPARTMENT_ID[collectionName];
  if (forcedDepartmentId) {
    return { status: 'update', update: { departmentId: forcedDepartmentId } };
  }

  const resolved = await resolveSingleDepartmentId(data, collectionName);
  if (resolved.status === 'ambiguous') {
    const fallbackDepartmentId =
      COLLECTION_AMBIGUITY_FALLBACK_DEPARTMENT_ID[collectionName];
    if (fallbackDepartmentId) {
      return {
        status: 'update',
        update: { departmentId: fallbackDepartmentId },
      };
    }

    return resolved;
  }

  return {
    status: 'update',
    update: { departmentId: resolved.departmentId },
  };
}

async function buildSiteUpdate(data) {
  const ids = new Set();

  const current = data.departmentIds;
  const currentNormalized = Array.isArray(current)
    ? current.map(normalizeDepartmentId).filter(Boolean)
    : [];
  await collectSiteDepartmentIds(data, ids, {
    resolveLinkedDocuments: true,
    includeExistingDepartmentIds: false,
  });

  const previous = [...currentNormalized].sort();

  if (ids.size === 0 && previous.length > 0) {
    if (arraysEqual(currentNormalized, previous) && arraysEqual(current, currentNormalized)) {
      return { status: 'skip' };
    }
    return { status: 'update', update: { departmentIds: previous } };
  }

  if (ids.size === 0) {
    return { status: 'ambiguous', reason: 'no site department candidate found' };
  }

  const next = Array.from(ids).sort();

  if (arraysEqual(previous, next)) return { status: 'skip' };

  return {
    status: 'update',
    update: { departmentIds: next },
  };
}

async function resolveSingleDepartmentId(data, collectionName) {
  const groups = await buildDepartmentPriorityGroups(data, collectionName);
  return resolveDepartmentFromGroups(groups);
}

async function buildDepartmentPriorityGroups(data, collectionName) {
  switch (collectionName) {
    case 'Agents':
      return [
        departmentGroup('agent department', data),
        await singleSiteDepartmentGroup('agent site', readPath(data, ['site'])),
      ];
    case 'Supervisors':
      return [departmentGroup('supervisor department', data)];
    case 'ZoneMembers':
      return [
        departmentGroup('zone member department', data),
        await zoneMemberPointingDepartmentGroup(
          'zone member pointings',
          data,
        ),
      ];
    case 'categorieTools':
    case 'CategorieTools':
      return [await categoryDepartmentGroup('category department', data)];
    case 'Tools':
      return [
        await toolDepartmentGroup('tool category', data),
        await singleSiteDepartmentGroup('tool site', readPath(data, ['site'])),
      ];
    case 'Notes':
      return [
        departmentGroup('note department', data),
        await noteAuthorDepartmentGroup(data),
        await noteSourceSupervisorDepartmentGroup(data),
        await singleSiteDepartmentGroup('note site', readPath(data, ['site'])),
      ];
    case 'CheckLists':
      return [
        await categoryDepartmentGroup('checklist category', readPath(data, ['cattool'])),
        await supervisorDepartmentGroup('checklist supervisor', readPath(data, ['supervisor'])),
        await singleSiteDepartmentGroup('checklist site', readPath(data, ['site'])),
      ];
    case 'sitePointings':
      return [
        await supervisorDepartmentGroup('site pointing supervisor', readPath(data, ['supervisor'])),
        await singleSiteDepartmentGroup('site pointing site', readPath(data, ['site'])),
      ];
    case 'agentPointings':
      return [
        await agentDepartmentGroup('agent pointing agent', readPath(data, ['agent'])),
        await singleSiteDepartmentGroup('agent pointing agent site', readPath(data, ['agent', 'site'])),
        await linkedAgentSiteDepartmentGroup('agent pointing linked agent site', readPath(data, ['agent'])),
      ];
    case 'rondierPointings':
      return [
        await agentDepartmentGroup('rondier pointing agent', readPath(data, ['agent'])),
        await singleSiteDepartmentGroup('rondier pointing site', readPath(data, ['site'])),
        await singleSiteDepartmentGroup('rondier pointing agent site', readPath(data, ['agent', 'site'])),
        await linkedAgentSiteDepartmentGroup('rondier pointing linked agent site', readPath(data, ['agent'])),
      ];
    case 'zonePointings':
      return [
        await zoneMemberDepartmentGroup('zone pointing member', readPath(data, ['zoneMember'])),
        await singleSiteDepartmentGroup('zone pointing site', readPath(data, ['site'])),
      ];
    case 'locationTracker':
      return [
        await supervisorDepartmentGroup(
          'location supervisor',
          readPath(data, ['supervisor']),
        ),
      ];
    case 'error_logs':
      return [
        await supervisorDepartmentGroup(
          'error log supervisor',
          readPath(data, ['supervisor']),
        ),
        await agentDepartmentGroup(
          'error log agent',
          readPath(data, ['agent']),
        ),
        await singleSiteDepartmentGroup(
          'error log site',
          readPath(data, ['site']),
        ),
      ];
    case 'toolPointings':
      return [
        await toolDepartmentGroup('tool pointing tool', readPath(data, ['tool'])),
        await singleSiteDepartmentGroup('tool pointing tool site', readPath(data, ['tool', 'site'])),
        await linkedToolSiteDepartmentGroup('tool pointing linked tool site', readPath(data, ['tool'])),
      ];
    default:
      return [
        departmentGroup('document department', data),
        await categoryDepartmentGroup('document category', readPath(data, ['catTool']) || readPath(data, ['cattool'])),
        await agentDepartmentGroup('document agent', readPath(data, ['agent'])),
        await supervisorDepartmentGroup('document supervisor', readPath(data, ['supervisor'])),
        await zoneMemberDepartmentGroup('document zone member', readPath(data, ['zoneMember'])),
        await toolDepartmentGroup('document tool', readPath(data, ['tool'])),
        await singleSiteDepartmentGroup('document site', readPath(data, ['site'])),
      ];
  }
}

function resolveDepartmentFromGroups(groups) {
  let deferredAmbiguity = null;

  for (const group of groups) {
    if (!group) continue;

    if (group.ids.size > 0) {
      if (group.ids.size === 1) {
        return {
          status: 'resolved',
          departmentId: Array.from(group.ids)[0],
        };
      }

      return {
        status: 'ambiguous',
        reason: `${group.label}: multiple department candidates: ${Array.from(group.ids).sort().join(', ')}`,
      };
    }

    if (!deferredAmbiguity && group.ambiguousReason) {
      deferredAmbiguity = group.ambiguousReason;
    }
  }

  return {
    status: 'ambiguous',
    reason: deferredAmbiguity || 'no department candidate found',
  };
}

function departmentGroup(label, data) {
  const ids = new Set();
  addDepartmentFromObject(ids, data);
  return { label, ids };
}

async function categoryDepartmentGroup(label, category) {
  const ids = new Set();
  addCategoryDepartmentIds(category, ids);
  await collectCategorieToolDocumentDepartmentIds(readPath(category, ['label']), ids);
  return { label, ids };
}

async function supervisorDepartmentGroup(label, supervisor) {
  const ids = new Set();
  await collectSupervisorDepartmentIds(supervisor, ids);
  return { label, ids };
}

async function agentDepartmentGroup(label, agent) {
  const ids = new Set();
  await collectAgentOwnDepartmentIds(agent, ids);
  return { label, ids };
}

async function zoneMemberDepartmentGroup(label, zoneMember) {
  const ids = new Set();
  await collectZoneMemberDepartmentIds(zoneMember, ids);
  return { label, ids };
}

async function zoneMemberPointingDepartmentGroup(label, zoneMember) {
  const ids = new Set();
  const uid = readPath(zoneMember, ['UID']);
  if (typeof uid !== 'string' || uid.trim() === '') {
    return { label, ids };
  }

  const snapshot = await db
    .collection('zonePointings')
    .where('zoneMember.UID', '==', uid.trim())
    .select('departmentId')
    .get();

  for (const doc of snapshot.docs) {
    addDepartmentId(ids, doc.data().departmentId);
  }

  return { label, ids };
}

async function toolDepartmentGroup(label, tool) {
  const ids = new Set();
  await collectToolCategoryDepartmentIds(tool, ids);
  return { label, ids };
}

async function singleSiteDepartmentGroup(label, site) {
  const ids = new Set();
  await collectSiteDepartmentIds(site, ids, { resolveLinkedDocuments: true });

  if (ids.size > 1) {
    return {
      label,
      ids: new Set(),
      ambiguousReason: `${label}: site has multiple departments: ${Array.from(ids).sort().join(', ')}`,
    };
  }

  return { label, ids };
}

async function linkedAgentSiteDepartmentGroup(label, agent) {
  const agentDoc = await getDocumentData('Agents', readPath(agent, ['code']));
  return singleSiteDepartmentGroup(label, readPath(agentDoc, ['site']));
}

async function linkedToolSiteDepartmentGroup(label, tool) {
  const toolDoc = await getDocumentData(
    'Tools',
    readPath(tool, ['serialNumber']),
  );
  return singleSiteDepartmentGroup(label, readPath(toolDoc, ['site']));
}

async function noteAuthorDepartmentGroup(data) {
  const label = 'note author';
  const ids = new Set();
  const authorUID = data.authorUID;
  const authorType = normalizeString(data.authorType);

  if (authorType === 'supervisor') {
    await collectSupervisorDocumentDepartmentIds(authorUID, ids);
  } else if (authorType === 'zonechief' || authorType === 'zone-chief') {
    await collectZoneMemberDocumentDepartmentIds(authorUID, ids);
  } else if (authorUID) {
    await collectSupervisorDocumentDepartmentIds(authorUID, ids);
    await collectZoneMemberDocumentDepartmentIds(authorUID, ids);
  }

  return { label, ids };
}

async function noteSourceSupervisorDepartmentGroup(data) {
  const label = 'note source supervisor';
  const ids = new Set();
  const site = readPath(data, ['site']);
  const source = normalizeName(data.source);
  if (!source) return { label, ids };

  if (site) {
    await collectSourceMatchedSiteSupervisorDepartments(site, source, ids);
  }

  const linkedSite = await getDocumentData(
    'Sites',
    data.siteUID || readPath(site, ['UID']),
  );
  if (linkedSite && linkedSite !== site) {
    await collectSourceMatchedSiteSupervisorDepartments(linkedSite, source, ids);
  }

  return { label, ids };
}

async function collectSourceMatchedSiteSupervisorDepartments(site, source, ids) {
  const supervisors = [
    readPath(site, ['supervisor']),
    readPath(site, ['supervisor_2']),
  ].filter((value) => value && typeof value === 'object');

  for (const supervisor of supervisors) {
    if (!doesSourceMatchPerson(source, supervisor)) continue;
    await collectSupervisorDepartmentIds(supervisor, ids);
  }
}

function addDepartmentFromObject(ids, data) {
  if (!data || typeof data !== 'object') return;

  addDepartmentId(ids, data.departmentId);
  addDepartmentId(ids, readPath(data, ['department', 'id']));
  addDepartmentId(ids, readPath(data, ['department', 'label']));
}

function addCategoryDepartmentIds(category, ids) {
  addDepartmentFromObject(ids, category);
}

async function collectSupervisorDepartmentIds(supervisor, ids) {
  addDepartmentFromObject(ids, supervisor);

  await collectSupervisorDocumentDepartmentIds(
    readPath(supervisor, ['UID']),
    ids,
  );
}

async function collectAgentOwnDepartmentIds(agent, ids) {
  addDepartmentFromObject(ids, agent);

  const doc = await getDocumentData('Agents', readPath(agent, ['code']));
  addDepartmentFromObject(ids, doc);
}

async function collectZoneMemberDepartmentIds(zoneMember, ids) {
  addDepartmentFromObject(ids, zoneMember);

  await collectZoneMemberDocumentDepartmentIds(
    readPath(zoneMember, ['UID']),
    ids,
  );
}

async function collectToolCategoryDepartmentIds(tool, ids) {
  addDepartmentFromObject(ids, tool);
  addCategoryDepartmentIds(readPath(tool, ['catTool']), ids);

  await collectCategorieToolDocumentDepartmentIds(
    readPath(tool, ['catTool', 'label']),
    ids,
  );

  const toolDoc = await getDocumentData(
    'Tools',
    readPath(tool, ['serialNumber']),
  );
  if (!toolDoc) return;

  addDepartmentFromObject(ids, toolDoc);
  addCategoryDepartmentIds(readPath(toolDoc, ['catTool']), ids);
  await collectCategorieToolDocumentDepartmentIds(
    readPath(toolDoc, ['catTool', 'label']),
    ids,
  );
}

async function collectSiteDepartmentIds(
  site,
  ids,
  { resolveLinkedDocuments = true, includeExistingDepartmentIds = true } = {},
) {
  if (!site || typeof site !== 'object') return;

  const departmentIds = site.departmentIds;
  if (includeExistingDepartmentIds && Array.isArray(departmentIds)) {
    for (const value of departmentIds) addDepartmentId(ids, value);
  }

  addDepartmentId(ids, readPath(site, ['departmentId']));
  addDepartmentId(ids, readPath(site, ['department', 'id']));
  addDepartmentId(ids, readPath(site, ['department', 'label']));
  addDepartmentId(ids, readPath(site, ['supervisor', 'departmentId']));
  addDepartmentId(ids, readPath(site, ['supervisor', 'department', 'id']));
  addDepartmentId(ids, readPath(site, ['supervisor', 'department', 'label']));
  addDepartmentId(ids, readPath(site, ['supervisor_2', 'departmentId']));
  addDepartmentId(ids, readPath(site, ['supervisor_2', 'department', 'id']));
  addDepartmentId(ids, readPath(site, ['supervisor_2', 'department', 'label']));

  if (!resolveLinkedDocuments) return;

  await collectSupervisorDocumentDepartmentIds(
    readPath(site, ['supervisor', 'UID']),
    ids,
  );
  await collectSupervisorDocumentDepartmentIds(
    readPath(site, ['supervisor_2', 'UID']),
    ids,
  );

  const siteUid = readPath(site, ['UID']);
  const siteDoc = await getDocumentData('Sites', siteUid);
  if (siteDoc && siteDoc !== site) {
    await collectSiteDepartmentIds(siteDoc, ids, {
      resolveLinkedDocuments: false,
      includeExistingDepartmentIds,
    });
    await collectSupervisorDocumentDepartmentIds(
      readPath(siteDoc, ['supervisor', 'UID']),
      ids,
    );
    await collectSupervisorDocumentDepartmentIds(
      readPath(siteDoc, ['supervisor_2', 'UID']),
      ids,
    );
  }
}

async function collectSupervisorDocumentDepartmentIds(uid, ids) {
  const supervisor = await getDocumentData('Supervisors', uid);
  if (!supervisor) return;

  addDepartmentId(ids, supervisor.departmentId);
  addDepartmentId(ids, readPath(supervisor, ['department', 'id']));
  addDepartmentId(ids, readPath(supervisor, ['department', 'label']));
}

async function collectZoneMemberDocumentDepartmentIds(uid, ids) {
  const zoneMember = await getDocumentData('ZoneMembers', uid);
  if (!zoneMember) return;

  addDepartmentId(ids, zoneMember.departmentId);
  addDepartmentId(ids, readPath(zoneMember, ['department', 'id']));
  addDepartmentId(ids, readPath(zoneMember, ['department', 'label']));
}

async function collectCategorieToolDocumentDepartmentIds(label, ids) {
  const category =
    (await getDocumentData('categorieTools', label)) ||
    (await getDocumentData('CategorieTools', label));
  if (!category) return;

  addDepartmentId(ids, category.departmentId);
  addDepartmentId(ids, readPath(category, ['department', 'id']));
  addDepartmentId(ids, readPath(category, ['department', 'label']));
}

async function getDocumentData(collectionName, docId) {
  if (typeof docId !== 'string' || docId.trim() === '') return null;

  const key = `${collectionName}/${docId}`;
  if (docCache.has(key)) return docCache.get(key);

  const snapshot = await db.collection(collectionName).doc(docId).get();
  const data = snapshot.exists ? snapshot.data() : null;
  docCache.set(key, data);
  return data;
}

function addDepartmentId(ids, value) {
  const id = normalizeDepartmentId(value);
  if (id) ids.add(id);
}

function normalizeDepartmentId(value) {
  const normalized = String(value || '')
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');

  switch (normalized) {
    case 'securite':
    case 'security':
      return 'security';
    case 'nettoyage':
    case 'cleaning':
      return 'cleaning';
    case 'direction':
      return 'direction';
    default:
      return normalized;
  }
}

function normalizeTenantId(value) {
  const normalized = String(value || '').trim().toLowerCase();
  return normalized || DEFAULT_TENANT_ID;
}

function normalizeDateField(value) {
  const normalized = String(value || '').trim();
  if (!normalized) fail('--date-field must not be empty.');
  if (!/^[A-Za-z0-9_.]+$/.test(normalized)) {
    fail('--date-field may contain only letters, numbers, underscores, and dots.');
  }
  return normalized;
}

function buildDateRange(parsedArgs) {
  const hasDateFrom = Boolean(parsedArgs.dateFrom);
  const hasDateTo = Boolean(parsedArgs.dateTo);
  const hasLastDays = Boolean(parsedArgs.lastDays);
  const hasCurrentMonth = Boolean(parsedArgs.currentMonth);
  const selectedModes = [
    hasDateFrom || hasDateTo,
    hasLastDays,
    hasCurrentMonth,
  ].filter(Boolean).length;

  if (selectedModes === 0) return null;
  if (selectedModes > 1) {
    fail('Use only one date mode: --date-from/--date-to, --last-days, or --current-month.');
  }

  if (hasLastDays) {
    const days = Number(parsedArgs.lastDays);
    if (!Number.isInteger(days) || days < 1) {
      fail('--last-days must be a positive integer.');
    }

    const todayStart = startOfUtcDay(new Date());
    return {
      start: addUtcDays(todayStart, -(days - 1)),
      end: addUtcDays(todayStart, 1),
    };
  }

  if (hasCurrentMonth) {
    const now = new Date();
    const start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
    const end = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1));
    return { start, end };
  }

  if (!hasDateFrom) fail('--date-to requires --date-from.');

  const start = parseIsoDateStart(parsedArgs.dateFrom, '--date-from');
  const end = hasDateTo
    ? parseIsoDateStart(parsedArgs.dateTo, '--date-to')
    : addUtcDays(startOfUtcDay(new Date()), 1);

  if (end <= start) fail('--date-to must be after --date-from.');

  return { start, end };
}

function parseIsoDateStart(value, label) {
  const normalized = String(value || '').trim();
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(normalized);
  if (!match) fail(`${label} must use YYYY-MM-DD format.`);

  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  const date = new Date(Date.UTC(year, month - 1, day));

  if (
    date.getUTCFullYear() !== year ||
    date.getUTCMonth() !== month - 1 ||
    date.getUTCDate() !== day
  ) {
    fail(`${label} is not a valid calendar date.`);
  }

  return date;
}

function startOfUtcDay(date) {
  return new Date(Date.UTC(
    date.getUTCFullYear(),
    date.getUTCMonth(),
    date.getUTCDate(),
  ));
}

function addUtcDays(date, days) {
  return new Date(date.getTime() + days * 24 * 60 * 60 * 1000);
}

function formatDuration(milliseconds) {
  const totalSeconds = Math.max(0, Math.round(milliseconds / 1000));
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${minutes}m ${String(seconds).padStart(2, '0')}s`;
}

function isTenantInScope(data) {
  const current = data.tenantId;
  if (typeof current !== 'string' || current.trim() === '') {
    return includeMissingTenant;
  }

  return normalizeTenantId(current) === tenantId;
}

function readPath(source, pathParts) {
  let current = source;
  for (const part of pathParts) {
    if (!current || typeof current !== 'object') return undefined;
    current = current[part];
  }
  return current;
}

function normalizeString(value) {
  return String(value || '')
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');
}

function normalizeName(value) {
  return normalizeString(value).replace(/[^a-z0-9]+/g, ' ').trim();
}

function doesSourceMatchPerson(source, person) {
  const firstName = normalizeName(readPath(person, ['firstName']));
  const lastName = normalizeName(readPath(person, ['lastName']));
  const code = normalizeName(readPath(person, ['code']));
  const email = normalizeName(readPath(person, ['email']));

  const names = [
    `${firstName} ${lastName}`.trim(),
    `${lastName} ${firstName}`.trim(),
    code,
    email,
  ].filter(Boolean);

  return names.includes(source);
}

function arraysEqual(left, right) {
  if (left.length !== right.length) return false;
  return left.every((value, index) => value === right[index]);
}

function emptyStats() {
  return {
    scanned: 0,
    inScope: 0,
    toUpdate: 0,
    updated: 0,
    skipped: 0,
    ambiguous: 0,
    errors: 0,
  };
}

function addTotals(totals, result) {
  totals.scanned += result.scanned;
  totals.inScope += result.inScope;
  totals.toUpdate += result.toUpdate;
  totals.updated += result.updated;
  totals.skipped += result.skipped;
  totals.ambiguous += result.ambiguous;
  totals.errors += result.errors;
}

function configureWriter(writer, stats) {
  if (!writer) return;

  writer.onWriteError((error) => {
    stats.errors += 1;
    console.error(
      `  write error ${error.documentRef.path}: ${error.code} ${error.message}`,
    );
    return error.failedAttempts < 3;
  });
}

function logDone(stats) {
  console.log(
    `  done: scanned=${stats.scanned}, inScope=${stats.inScope}, toUpdate=${stats.toUpdate}, updated=${stats.updated}, skipped=${stats.skipped}, ambiguous=${stats.ambiguous}, errors=${stats.errors}`,
  );
  console.log('');
}

function parseArgs(argv) {
  const parsed = {};

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];

    if (arg === '--execute') {
      parsed.execute = true;
      continue;
    }

    if (arg === '--log-skipped') {
      parsed.logSkipped = true;
      continue;
    }

    if (arg === '--current-month') {
      parsed.currentMonth = true;
      continue;
    }

    if (arg.startsWith('--')) {
      const key = arg.slice(2).replace(/-([a-z])/g, (_, char) =>
        char.toUpperCase(),
      );
      const next = argv[index + 1];
      if (!next || next.startsWith('--')) {
        fail(`${arg} requires a value.`);
      }
      parsed[key] = next;
      index += 1;
      continue;
    }

    fail(`Unknown argument: ${arg}`);
  }

  return parsed;
}

function fail(message) {
  console.error(message);
  process.exit(1);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
