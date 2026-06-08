#!/usr/bin/env node

/*
 * Backfill tenantId on historical Firestore documents.
 *
 * Safe by design:
 * - dry-run by default;
 * - updates only top-level tenantId;
 * - never rewrites whole documents;
 * - skips documents where tenantId is already a non-empty string;
 * - excludes Managers by default because manager tenant assignment is explicit.
 *
 * Usage:
 *   node scripts/backfill_tenant_ml.js
 *   node scripts/backfill_tenant_ml.js --execute
 *   node scripts/backfill_tenant_ml.js --collections Sites,Agents
 *   node scripts/backfill_tenant_ml.js --project spas-cd4c9 --execute
 *   node scripts/backfill_tenant_ml.js --project spas-cd4c9 --credentials C:\path\service-account.json --execute
 *
 * Auth:
 *   Use one of:
 *   - gcloud auth application-default login
 *   - set GOOGLE_APPLICATION_CREDENTIALS=C:\path\service-account.json
 */

const admin = require('firebase-admin');
const path = require('path');

const DEFAULT_TENANT_ID = 'ml';

const DEFAULT_COLLECTIONS = [
  'Supervisors',
  'Sites',
  'Agents',
  'Zones',
  'ZoneMembers',
  'Tools',
  'Notes',
  'CheckLists',
  'sitePointings',
  'agentPointings',
  'zonePointings',
  'rondierPointings',
  'toolPointings',
  'locationTracker',
  'error_logs',
];

const args = parseArgs(process.argv.slice(2));
const execute = Boolean(args.execute);
const tenantId = args.tenant || DEFAULT_TENANT_ID;
const pageSize = Number(args.pageSize || 500);
const maxDocs = args.maxDocs ? Number(args.maxDocs) : null;
const projectId = args.project || process.env.GCLOUD_PROJECT || undefined;
const credentialsPath = args.credentials || process.env.GOOGLE_APPLICATION_CREDENTIALS;
const collections = args.collections
  ? args.collections.split(',').map((value) => value.trim()).filter(Boolean)
  : DEFAULT_COLLECTIONS;

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

async function main() {
  console.log('Tenant backfill');
  console.log(`Mode: ${execute ? 'EXECUTE' : 'DRY-RUN'}`);
  console.log(`Project: ${projectId || '(default credentials project)'}`);
  console.log(`Credentials: ${credentialsPath || '(application default)'}`);
  console.log(`Tenant: ${tenantId}`);
  console.log(`Page size: ${pageSize}`);
  if (maxDocs !== null) console.log(`Max docs per collection: ${maxDocs}`);
  console.log(`Collections: ${collections.join(', ')}`);
  console.log('');

  if (!execute) {
    console.log('Dry-run only. Add --execute to write tenantId.');
    console.log('');
  }

  const totals = {
    scanned: 0,
    toUpdate: 0,
    updated: 0,
    skipped: 0,
    errors: 0,
  };

  for (const collectionName of collections) {
    const result = await backfillCollection(collectionName);
    totals.scanned += result.scanned;
    totals.toUpdate += result.toUpdate;
    totals.updated += result.updated;
    totals.skipped += result.skipped;
    totals.errors += result.errors;
  }

  console.log('');
  console.log('Summary');
  console.log(`Scanned: ${totals.scanned}`);
  console.log(`Need tenantId: ${totals.toUpdate}`);
  console.log(`Updated: ${totals.updated}`);
  console.log(`Skipped: ${totals.skipped}`);
  console.log(`Errors: ${totals.errors}`);

  if (!execute) {
    console.log('');
    console.log('No data was modified. Re-run with --execute to apply changes.');
  }

  if (totals.errors > 0) process.exitCode = 1;
}

async function backfillCollection(collectionName) {
  console.log(`Collection: ${collectionName}`);

  const stats = {
    scanned: 0,
    toUpdate: 0,
    updated: 0,
    skipped: 0,
    errors: 0,
  };

  let lastDoc = null;

  while (true) {
    let query = db
      .collection(collectionName)
      .orderBy(fieldPathDocumentId)
      .limit(pageSize);

    if (lastDoc) query = query.startAfter(lastDoc);

    const snapshot = await query.get();
    if (snapshot.empty) break;

    const writer = execute ? db.bulkWriter() : null;

    if (writer) {
      writer.onWriteError((error) => {
        stats.errors += 1;
        console.error(
          `  write error ${error.documentRef.path}: ${error.code} ${error.message}`,
        );
        return error.failedAttempts < 3;
      });
    }

    for (const doc of snapshot.docs) {
      if (maxDocs !== null && stats.scanned >= maxDocs) break;

      stats.scanned += 1;
      const data = doc.data();
      const currentTenantId = data.tenantId;
      const needsTenantId =
        typeof currentTenantId !== 'string' || currentTenantId.trim() === '';

      if (!needsTenantId) {
        stats.skipped += 1;
        continue;
      }

      stats.toUpdate += 1;

      if (execute) {
        writer.update(doc.ref, { tenantId });
        stats.updated += 1;
      }
    }

    if (writer) await writer.close();

    lastDoc = snapshot.docs[snapshot.docs.length - 1];

    console.log(
      `  scanned=${stats.scanned} toUpdate=${stats.toUpdate} updated=${stats.updated} skipped=${stats.skipped}`,
    );

    if (maxDocs !== null && stats.scanned >= maxDocs) break;
    if (snapshot.size < pageSize) break;
  }

  console.log(
    `  done: scanned=${stats.scanned}, toUpdate=${stats.toUpdate}, updated=${stats.updated}, skipped=${stats.skipped}, errors=${stats.errors}`,
  );
  console.log('');

  return stats;
}

function parseArgs(argv) {
  const parsed = {};

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];

    if (arg === '--execute') {
      parsed.execute = true;
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
