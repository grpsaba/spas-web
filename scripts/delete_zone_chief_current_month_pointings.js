#!/usr/bin/env node

/*
 * Delete zonePointings for one zone chief over the current month.
 *
 * Safe by design:
 * - dry-run by default;
 * - requires --uid;
 * - filters by embedded zoneMember.UID;
 * - deletes only documents whose datetimestamp/date is within the target month.
 *
 * Usage:
 *   node delete_zone_chief_current_month_pointings.js --uid ZONE_MEMBER_UID
 *   node delete_zone_chief_current_month_pointings.js --uid ZONE_MEMBER_UID --execute
 *   node delete_zone_chief_current_month_pointings.js --uid ZONE_MEMBER_UID --month 2026-07 --execute
 *   node delete_zone_chief_current_month_pointings.js --uid ZONE_MEMBER_UID --project spas-cd4c9
 *   node delete_zone_chief_current_month_pointings.js --uid ZONE_MEMBER_UID --project spas-cd4c9 --credentials C:\path\service-account.json --execute
 *
 * Auth:
 *   Use one of:
 *   - gcloud auth application-default login
 *   - set GOOGLE_APPLICATION_CREDENTIALS=C:\path\service-account.json
 */

const admin = require('firebase-admin');
const path = require('path');

const args = parseArgs(process.argv.slice(2));
const uid = (args.uid || '').trim();
const execute = Boolean(args.execute);
const projectId = args.project || process.env.GCLOUD_PROJECT || undefined;
const credentialsPath =
  args.credentials || process.env.GOOGLE_APPLICATION_CREDENTIALS;
const batchSize = Number(args.batchSize || 450);

if (!uid) {
  fail('Missing required --uid ZONE_MEMBER_UID.');
}

if (!Number.isInteger(batchSize) || batchSize < 1 || batchSize > 500) {
  fail('--batch-size must be an integer between 1 and 500.');
}

const monthRange = parseMonthRange(args.month);

admin.initializeApp({
  credential: credentialsPath
    ? admin.credential.cert(require(path.resolve(credentialsPath)))
    : admin.credential.applicationDefault(),
  projectId,
});

const db = admin.firestore();

async function main() {
  console.log('Delete zone chief current-month pointings');
  console.log(`Mode: ${execute ? 'EXECUTE' : 'DRY-RUN'}`);
  console.log(`Project: ${projectId || '(default credentials project)'}`);
  console.log(`Credentials: ${credentialsPath || '(application default)'}`);
  console.log(`Zone member UID: ${uid}`);
  console.log(`Month start: ${monthRange.start.toISOString()}`);
  console.log(`Month end: ${monthRange.end.toISOString()}`);
  console.log('');

  if (!execute) {
    console.log('Dry-run only. Add --execute to delete matching documents.');
    console.log('');
  }

  const snapshot = await db
    .collection('zonePointings')
    .where('zoneMember.UID', '==', uid)
    .get();

  const candidates = [];
  const skippedWithoutDate = [];
  const siteIds = new Set();
  const countsByDay = new Map();

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const pointingDate = readPointingDate(data);
    if (!pointingDate) {
      skippedWithoutDate.push(doc.id);
      continue;
    }

    if (pointingDate >= monthRange.start && pointingDate < monthRange.end) {
      const siteUid = readPath(data, ['site', 'UID']) || '';
      const dayKey = formatDay(pointingDate);
      if (siteUid) siteIds.add(siteUid);
      countsByDay.set(dayKey, (countsByDay.get(dayKey) || 0) + 1);

      candidates.push({
        ref: doc.ref,
        id: doc.id,
        date: pointingDate,
        siteName: readPath(data, ['site', 'name']) || '',
        siteUid,
      });
    }
  }

  console.log(`Scanned docs for UID: ${snapshot.size}`);
  console.log(`Matching current-month docs: ${candidates.length}`);
  console.log(`Unique sites in matching docs: ${siteIds.size}`);
  console.log(`Days represented: ${countsByDay.size}`);
  console.log(`Skipped without readable date: ${skippedWithoutDate.length}`);

  if (countsByDay.size > 0) {
    console.log('');
    console.log('Matching docs by day:');
    for (const [day, count] of [...countsByDay.entries()].sort()) {
      console.log(`- ${day}: ${count}`);
    }
  }

  for (const item of candidates) {
    const site = item.siteName || item.siteUid || '(site unknown)';
    console.log(`- ${item.id} | ${item.date.toISOString()} | ${site}`);
  }

  if (skippedWithoutDate.length > 0) {
    console.log('');
    console.log('Documents skipped because date could not be read:');
    for (const id of skippedWithoutDate) console.log(`- ${id}`);
  }

  if (!execute) {
    console.log('');
    console.log('No data was deleted. Re-run with --execute to apply deletion.');
    return;
  }

  let deleted = 0;
  for (let index = 0; index < candidates.length; index += batchSize) {
    const batch = db.batch();
    const chunk = candidates.slice(index, index + batchSize);
    for (const item of chunk) batch.delete(item.ref);
    await batch.commit();
    deleted += chunk.length;
    console.log(`Deleted ${deleted}/${candidates.length}`);
  }

  console.log('');
  console.log(`Done. Deleted documents: ${deleted}`);
}

function parseMonthRange(monthArg) {
  if (!monthArg) {
    const now = new Date();
    return buildMonthRange(now.getFullYear(), now.getMonth() + 1);
  }

  const match = /^(\d{4})-(\d{2})$/.exec(monthArg);
  if (!match) {
    fail('--month must use YYYY-MM format, for example --month 2026-07.');
  }

  const year = Number(match[1]);
  const month = Number(match[2]);
  if (month < 1 || month > 12) {
    fail('--month must contain a month between 01 and 12.');
  }

  return buildMonthRange(year, month);
}

function buildMonthRange(year, month) {
  const start = new Date(year, month - 1, 1, 0, 0, 0, 0);
  const end =
    month === 12
      ? new Date(year + 1, 0, 1, 0, 0, 0, 0)
      : new Date(year, month, 1, 0, 0, 0, 0);
  return { start, end };
}

function formatDay(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

function readPointingDate(data) {
  const timestamp = data.datetimestamp;
  if (timestamp && typeof timestamp.toDate === 'function') {
    return timestamp.toDate();
  }

  if (timestamp instanceof Date) return timestamp;

  if (typeof timestamp === 'string') {
    const parsed = new Date(timestamp);
    if (!Number.isNaN(parsed.getTime())) return parsed;
  }

  const date = data.date;
  if (date && typeof date.toDate === 'function') return date.toDate();
  if (date instanceof Date) return date;

  if (typeof date === 'string') {
    const parsed = new Date(date);
    if (!Number.isNaN(parsed.getTime())) return parsed;
  }

  return null;
}

function readPath(value, pathParts) {
  let current = value;
  for (const part of pathParts) {
    if (!current || typeof current !== 'object') return undefined;
    current = current[part];
  }
  return current;
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
      const key = arg.slice(2).replace(/-([a-z])/g, (_, letter) =>
        letter.toUpperCase(),
      );
      const next = argv[index + 1];
      if (!next || next.startsWith('--')) {
        fail(`Missing value for ${arg}.`);
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
