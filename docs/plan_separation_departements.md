# Plan de separation des departements

Date: 2026-07-09

Ce document est la reference backoffice du chantier partage avec
`spasmobile/docs/plan_separation_departements.md`.

## Regles garde-fous

- `tenantId` reste le pays / la filiale.
- `departmentId` est l'ID technique stable d'un departement.
- `departmentIds` sert aux documents multi-departements, surtout les sites.
- Ne pas activer de filtre departement global pour le Mali tant que
  l'historique n'est pas complet.
- Les nouveaux champs doivent etre ecrits avant les backfills et avant les
  filtres stricts.
- `pointageMode` pilote les superviseurs; `zoneChiefPointageMode` pilote les
  chefs de zone et retombe sur `pointageMode` quand il n'existe pas.

## Etat backoffice

- `Department` porte maintenant `id`, `label` et `active`.
- `DepartmentService` ecrit dans `departments/{id}`.
- Les anciens documents sans champ `id` restent lisibles via l'ID du document.
- `Manager` porte `departmentScope` (`all` ou `limited`) et `departmentIds`.
- `DepartmentScope` est branche dans les services backoffice principaux pour
  les managers limites.
- `TenantScope.applyTenantIdForWrite` normalise aussi `departmentId` quand le
  modele en porte un.
- Les sites ecrivent `departmentIds`; en absence de selection explicite, ils
  reprennent les departements des superviseurs assignes.
- `CategorieToolService` passe par le helper de scope pour garantir
  `tenantId` et `departmentId`.
- Les services d'ecriture metier deja branches sur `TenantScope` couvrent
  agents, superviseurs, chefs de zone, notes, outils, checklists et pointages.
- La gestion des pays expose maintenant deux modes de pointage: superviseurs et
  chefs de zone.
- Les dashboards, statistiques, rapports et exports de pointages utilisent le
  scope departement du manager.
- Le cache de pagination des pointages distingue le pays et les departements.
- Un manager configure en scope limite sans departement ne voit aucune donnee.
- Le mobile filtre les documents simples par `departmentId` et les sites par
  `departmentIds` a partir du profil connecte.

## Prochaines etapes

1. Surveiller les index Firestore demandes par les nouvelles requetes
   `tenantId + departmentId` et `tenantId + departmentIds`.
2. Verifier les pages backoffice avec un manager limite par departement.
3. Verifier les parcours mobile superviseur et chef de zone pour chaque
   departement.

Script backfill:

```txt
spas-web/scripts/backfill_department_fields.js
```

Commandes:

```txt
cd spas-web/scripts
npm run backfill:departments:dry-run
npm run backfill:departments:execute
```

Le script ne se limite pas au JSON embarque: quand un document contient un
identifiant lie, il relit aussi les documents sources (`Sites`, `Supervisors`,
`Agents`, `ZoneMembers`, `Tools`, `categorieTools`) pour reduire les cas
ambigus sans deviner.

## Etat apres backfill

- Les backfills ont ete executes sur les collections utilisees par
  `spasmobile` et `spas-web`.
- `Sites` est renseigne via `departmentIds`.
- Les documents metier simples sont renseignes via `departmentId`.
- Les fallbacks metier appliques a la migration sont:
  - `zonePointings`: `security`;
  - `agentPointings`: `direction`;
  - `Notes` encore ambigues: `security`.
- Les filtres departement sont maintenant branches dans les services
  backoffice principaux pour les managers limites.
