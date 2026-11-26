# Pointage géo avec photo de secours — côté web

Back-office du contrat de données partagé avec l'app mobile (spasmobile).
Rien n'est déployé : ni hébergement, ni index, ni règles.

## Écrans

| Écran | Où | Ce qui est écrit dans Firestore |
|---|---|---|
| Configuration Mobile → « Pointage par géolocalisation » | `lib/mobile_config/geo_pointing_settings_panel.dart` | `app_config/global.geoPointing` uniquement (`set` avec `mergeFields: ['geoPointing']`), après confirmation. Les autres champs du document ne sont pas touchés. |
| Fiche superviseur / chef de zone → « Mode de pointage » | `lib/supervisor/supervisor_form.dart`, `lib/zone_member/zone_member_form_modern.dart` | `pointageModeOverride` = `photo` / `geo`, ou champ supprimé pour « Selon le pays ». Seul le formulaire écrit ce champ. |
| Tableaux de pointage | colonne « Méthode » | lecture seule |
| Erreurs de pointage | nouveaux filtres, cartes du détail, « Parcours de la visite » | lecture seule (la résolution existante ne change pas) |
| Suivi géolocalisation | menu Pointages, route `/suivi-geolocalisation` | lecture seule |

### Réglages géo (bornes)

| Champ | Bornes | Recommandé |
|---|---|---|
| `attemptTimeoutSeconds` | 15–45 s (pas de 5 s au stepper, 1 s au curseur) | 25 |
| `attemptsBeforePhoto` | 1–3 | 2 |
| `photoFallbackEnabled` | Oui / Non | Oui |
| `accuracyRule` | `normal` / `strict` | `normal` |

Une valeur hors bornes lue dans Firestore est ramenée dans les bornes ; un
document ou un champ absent affiche les valeurs recommandées. La modification
est réservée aux profils qui peuvent déjà couper le suivi continu
(Administrateur / Directeur Général avec le droit « ajouter » sur Config
Mobile), car le réglage s'applique à tous les pays.

### Taux de secours photo

`photo_fallback ÷ (geo + photo_fallback)` sur la période. Les pointages faits
en mode Photo ne comptent pas. Anciens pointages sans `pointingMethod` :
`geoMetadata` sans photo = Géo, photo = Photo, sinon « inconnu » (affiché « — »).

## À faire par le propriétaire

### 1. Règles Firestore

La collection `mobile_events` est nouvelle : les managers du back-office
doivent pouvoir la **lire** (avec le même filtre pays que les autres
collections). Sans cette règle, le journal affiche une erreur et le parcours
de la visite affiche « Non chargé — mobile_events : permission-denied » mais
montre le reste.

### 2. Index composites (Firestore les demande au premier usage)

Les requêtes de « Parcours de la visite » n'utilisent que des égalités
(`visitId` + filtres pays/département) : aucun index composite.
Les statistiques réutilisent les plages de dates déjà utilisées par les écrans
de pointage et d'erreurs.

Nouveaux index nécessaires (ajouter `tenantId ASC` en premier champ pour les
profils limités à un pays, et `departmentId ASC` pour les profils limités à
un département) :

| Collection | Champs | Utilisé par |
|---|---|---|
| `error_logs` | `attemptOutcome ASC`, `timestamp DESC` | filtre « Résultat de l'essai GPS » |
| `error_logs` | `appVersion ASC`, `timestamp DESC` | filtre « Version de l'app » |
| `error_logs` | `deviceInfo.model ASC`, `timestamp DESC` | filtre « Modèle de téléphone » |
| `mobile_events` | `tenantId ASC`, `timestamp DESC` | journal (profil limité à un pays) |
| `mobile_events` | `userId ASC`, `timestamp DESC` | journal filtré par personne |
| `mobile_events` | `event ASC`, `timestamp DESC` | journal filtré par action |
| `mobile_events` | `userId ASC`, `event ASC`, `timestamp DESC` | journal filtré par personne et action |

Combinés aux filtres existants (statut, type d'erreur…), Firestore peut
demander d'autres combinaisons : le message d'erreur contient le lien de
création de l'index exact. Extrait pour `firestore.indexes.json` :

```json
{
  "indexes": [
    {"collectionGroup": "error_logs", "queryScope": "COLLECTION", "fields": [
      {"fieldPath": "attemptOutcome", "order": "ASCENDING"},
      {"fieldPath": "timestamp", "order": "DESCENDING"}]},
    {"collectionGroup": "error_logs", "queryScope": "COLLECTION", "fields": [
      {"fieldPath": "appVersion", "order": "ASCENDING"},
      {"fieldPath": "timestamp", "order": "DESCENDING"}]},
    {"collectionGroup": "error_logs", "queryScope": "COLLECTION", "fields": [
      {"fieldPath": "deviceInfo.model", "order": "ASCENDING"},
      {"fieldPath": "timestamp", "order": "DESCENDING"}]},
    {"collectionGroup": "mobile_events", "queryScope": "COLLECTION", "fields": [
      {"fieldPath": "tenantId", "order": "ASCENDING"},
      {"fieldPath": "timestamp", "order": "DESCENDING"}]},
    {"collectionGroup": "mobile_events", "queryScope": "COLLECTION", "fields": [
      {"fieldPath": "userId", "order": "ASCENDING"},
      {"fieldPath": "timestamp", "order": "DESCENDING"}]},
    {"collectionGroup": "mobile_events", "queryScope": "COLLECTION", "fields": [
      {"fieldPath": "event", "order": "ASCENDING"},
      {"fieldPath": "timestamp", "order": "DESCENDING"}]},
    {"collectionGroup": "mobile_events", "queryScope": "COLLECTION", "fields": [
      {"fieldPath": "userId", "order": "ASCENDING"},
      {"fieldPath": "event", "order": "ASCENDING"},
      {"fieldPath": "timestamp", "order": "DESCENDING"}]}
  ]
}
```

### 3. Menu et droits

« Suivi géolocalisation » apparaît pour les profils qui voient « Erreurs
Pointage » (module `ERROR_LOG`). Il peut être masqué comme les autres entrées
via `app_config/global.drawerMenuItems.suivi_geolocalisation`.

### 4. Purge de `mobile_events`

Le contrat prévoit `expireAt` : activer une règle TTL Firestore sur ce champ
si l'app mobile ne s'en charge pas.
