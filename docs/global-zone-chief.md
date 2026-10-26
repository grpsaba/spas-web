# Chef de zone global Sécurité

Dans **Chefs de zone → Ajouter / Modifier → Affectation**, choisir le pays,
le département **Sécurité**, puis **Toutes les zones · Sécurité**.
La zone devient facultative et est enregistrée à `null` en mode global.
Le pays d'un profil existant reste fixé pendant son édition.

Les documents `ZoneMembers` partagent ce contrat avec `spasmobile` :

- `zoneScope: "assigned"` : zone assignée ; valeur par défaut des anciens profils.
- `zoneScope: "global"` : toutes les zones du pays, uniquement avec
  `departmentId: "security"` et un `tenantId` explicitement renseigné.
- Un site accessible doit être actif, appartenir au même pays et contenir
  `security` dans `departmentIds`. Un site partagé Sécurité / Nettoyage est inclus.
- Une valeur de périmètre inconnue ne donne jamais d'accès global.

Les listes, compteurs et rapports prennent en compte ce périmètre. La zone d'un
pointage est celle du site visité, puisque le chef global n'a pas de zone assignée.
Le pointage manuel n'est pas adapté dans cette livraison : ses sélecteurs
existants restent limités aux chefs avec une zone assignée.

## Mise en service

Livrer également la version mobile correspondante avant d'activer des profils
globaux. Les anciennes versions mobiles exigent une zone assignée.
Après changement du profil, actualiser l'accueil mobile avec une connexion réseau.

Les règles et index Firestore ne sont pas versionnés dans ces dépôts. Aucun
changement de données ou déploiement Firebase n'est effectué par cette branche.
Les contrôles applicatifs ne remplacent pas les règles Firestore.

Vérifier les index correspondant à ces requêtes lors de la recette Firebase :

| Collection | Filtres | Tri |
| --- | --- | --- |
| `Sites` | `tenantId`, `departmentIds` (array-contains), `actif` ; ajouter `zone.codeZone` pour un chef classique | Aucun |
| `Notes` (mobile) | `tenantId`, `departmentId`, `viewed` ; ajouter `site.zone.codeZone` pour un chef classique | `date` décroissant |
| `zonePointings` (rapports web par zone) | `site.zone.codeZone`, ainsi que les filtres pays/département et site/chef sélectionnés | `date` selon le rapport |

Une erreur `failed-precondition` Firestore indique l'index exact à créer.
Tester avec deux zones du même pays, un site Nettoyage et un site d'un autre pays.

## Validation locale

`flutter test --no-pub test/services/zone_chief_scope_test.dart test/zone_member/zone_member_scope_field_test.dart`

`flutter build web --no-pub`

Les tests dédiés vérifient la compatibilité des anciens profils, le département,
le pays, le filtrage des sites et le choix de périmètre dans le formulaire.
