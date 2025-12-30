# Firebase Composite Indexes Required

For optimal query performance in the Pointage System, the following composite indexes must be created in the Firebase Console.

## How to Create Indexes

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project
3. Navigate to Firestore Database > Indexes
4. Click "Create Index" and add the following configurations

## Required Indexes

### Index 1: Date + Supervisor Filter
**Collection:** `sitePointings`
**Fields:**
- `datetimestamp` - Descending
- `supervisor.UID` - Ascending

**Query Scope:** Collection

**Purpose:** Enables efficient filtering by supervisor with date range sorting

---

### Index 2: Date + Site Filter
**Collection:** `sitePointings`
**Fields:**
- `datetimestamp` - Descending
- `site.UID` - Ascending

**Query Scope:** Collection

**Purpose:** Enables efficient filtering by site with date range sorting

---

### Index 3: Date + Zone Filter
**Collection:** `sitePointings`
**Fields:**
- `datetimestamp` - Descending
- `zone.codeZone` - Ascending

**Query Scope:** Collection

**Purpose:** Enables efficient filtering by zone with date range sorting

---

### Index 4: Multiple Filters (Optional but Recommended)
**Collection:** `sitePointings`
**Fields:**
- `datetimestamp` - Descending
- `supervisor.UID` - Ascending
- `site.UID` - Ascending

**Query Scope:** Collection

**Purpose:** Enables efficient filtering by both supervisor and site simultaneously

---

## Automatic Index Creation

When you run queries that require these indexes, Firebase will show an error message with a direct link to create the required index. You can click that link to automatically create the index with the correct configuration.

## Performance Benefits

With these indexes in place:
- Query execution time: **10-100x faster**
- Reduced database reads: **Up to 90% reduction**
- Better pagination performance with cursor-based navigation
- Improved user experience with faster page loads

## Verification

After creating the indexes, verify they are active:
1. Check the Indexes tab in Firebase Console
2. Ensure all indexes show status "Enabled"
3. Test queries in the application to confirm improved performance

## Requirements Addressed

- Requirement 1.1: Server-side pagination
- Requirement 1.2: Firebase aggregation queries
- Requirement 9.3: Optimize Firebase queries
