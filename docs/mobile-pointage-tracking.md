# Modes de pointage et suivi GPS continu

La page `/mobile-config` sépare trois réglages :

| Réglage | Portée | Stockage |
| --- | --- | --- |
| Mode superviseur Photo / Géo | Un pays, superviseurs | `tenants/{pays}.pointageMode` |
| Mode chef de zone Photo / Géo | Un pays, chefs de zone | `tenants/{pays}.zoneChiefPointageMode` |
| Autoriser le suivi GPS continu | Tous les pays | `app_config/global.backgroundTrackingEnabled` |

Le suivi continu demande une session active, le réglage global actif et le mode
Géo pour **le rôle connecté**. Les modes des deux rôles sont indépendants.

| Superviseur | Chef de zone | Global actif : suivi continu |
| --- | --- | --- |
| Photo | Photo | Aucun des deux rôles |
| Photo | Géo | Chef de zone uniquement |
| Géo | Photo | Superviseur uniquement |
| Géo | Géo | Les deux rôles |

Global désactivé : aucun suivi continu. Un pointage Géo peut toujours effectuer
sa mesure GPS au premier plan. Une mesure en cours conserve son accès GPS même
si le suivi continu est coupé. En mode Photo, une position est facultative ;
une position absente reste absente et ne prend jamais les coordonnées du site.

## Enregistrement et compatibilité

Le switch global est enregistré immédiatement, avec état d'attente et retour
d'erreur. Sa modification est réservée aux administrateurs et aux directeurs
généraux disposant du droit d'ajout du module de configuration mobile.
L'interface décrit une autorisation ; elle ne certifie pas l'activité d'un
téléphone. Les droits Firestore doivent autoriser les mêmes opérations.

Les écritures des modes utilisent une transaction et ne modifient que les
rôles demandés. Pour un ancien pays sans champ chef de zone explicite, le
changement du superviseur matérialise d'abord l'ancienne valeur effective du
chef de zone, y compris les anciens alias. Une modification de libellé conserve
les changements de modes effectués pendant l'ouverture du formulaire.

Enregistrer ou réinitialiser les paramètres photo préserve le switch global.
Il n'y a aucune migration de données à exécuter pour cette livraison.

## Comportement mobile

L'application écoute le pays connecté et la configuration globale. Elle
réévalue le suivi à la connexion, au changement de rôle/pays, au retour dans
l'application et après synchronisation. Une déconnexion arrête immédiatement
la demande de suivi et efface la session locale même sans réseau.

La dernière configuration valide est conservée par pays sur le téléphone.
Une réponse réseau ancienne n'écrase pas une mise à jour reçue entre-temps.
Une réponse vide issue du cache Firestore ne supprime pas une configuration
valide. La suppression confirmée d'un pays invalide sa configuration locale.
Sans configuration pays connue, le pointage demande une synchronisation ;
il ne choisit pas Photo implicitement.

Le mobile affiche le mode du rôle, l'état réel du suivi et l'usage d'une
configuration conservée localement. Hors réseau, une modification distante
ne peut prendre effet qu'après réception par le téléphone.

## Recette avant mise en service

Livrer les versions web et mobile correspondantes. Une ancienne application
mobile peut ignorer le réglage global. Ces changements ne déploient aucune
version ni ne modifient les réglages Firebase réels.

1. Dans un pays de recette, tester les quatre combinaisons Photo/Géo avec
   un compte superviseur puis un compte chef de zone. Vérifier que modifier
   un rôle préserve l'autre et les autres pays.
2. Couper le suivi global pendant une mesure Géo : la mesure peut finir,
   puis le suivi continu reste coupé. Réactiver et vérifier la reprise
   uniquement pour les rôles en Géo.
3. Refuser les autorisations GPS puis les accorder ; couper puis réactiver
   la localisation ; verrouiller le téléphone et revenir dans l'application.
   Vérifier la notification Android, les positions reçues et l'état affiché.
4. Charger une configuration, passer hors ligne et redémarrer. Tester aussi
   une déconnexion hors ligne suivie d'un redémarrage : aucune session ne
   doit être restaurée après cette déconnexion.
5. En Photo sans GPS, vérifier le pointage et l'absence de position inventée.
   Sans configuration pays connue, vérifier le message de synchronisation.
6. Ouvrir deux formulaires web et modifier des rôles distincts. Vérifier
   qu'enregistrer les paramètres photo ne remet pas le suivi global à ON.

Le verrouillage, la gestion d'énergie et les autorisations système exigent
une recette sur appareil réel. Les descriptions d'usage de localisation et
le mode d'arrière-plan `location` sont déclarés pour iOS. Ces ajouts natifs
nécessitent une nouvelle version iPhone et une recette sur iPhone ; un patch
Dart seul ne les installe pas.

## Vérification automatisée

Web :

```sh
flutter test --no-pub test/services/tenant_pointage_modes_test.dart test/services/mobile_config_test.dart test/mobile_config/background_tracking_control_test.dart
```

Mobile :

```sh
flutter test --no-pub test/services/background_tracking_controller_test.dart test/services/live_config_store_test.dart test/models/site_geo_metadata_test.dart test/services/gps test/services/site_location test/widgets/site_location_status_test.dart test/widgets/site_location_dialog_test.dart
```
