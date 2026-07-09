# Analyse existant avant grosse mise a jour

Date: 2026-06-04

Repos analyses:

- Web: `C:\Users\hp\Documents\spas\main\spas-web`
- Mobile: `C:\Users\hp\Documents\spas\main\spasmobile`

Objectif: comprendre l'existant avant une grosse mise a jour, noter les risques actuels, et garder une liste de decisions techniques a arbitrer avant implementation.

## Resume rapide

Le systeme SPAS est compose de deux applications Flutter:

- `spas-web`: backoffice web Firebase, routing centralise avec GoRouter, modules CRUD, reporting, pointages, logs d'erreurs.
- `spasmobile`: application terrain superviseur, avec auth offline, cache local Hive, queue de synchronisation, GPS/background tracking, photos de pointage, FCM, Shorebird/update.

La base est fonctionnelle, mais elle a deux generations de code:

- une generation historique: gros fichiers, logique UI + Firestore melangee, navigation par objets en memoire;
- une generation plus recente: providers, repositories, cache, modeles dedies, logs d'erreurs, configuration pilotable.

La grosse mise a jour devrait s'appuyer sur les patterns recents au lieu de repartir de zero.

## Etat du repo web

### Architecture observee

- Entree: `lib/main.dart`
- Router: `lib/router.dart`
- Shell UI: `lib/administration/home.dart`
- Menu: `lib/models/menu_item_model.dart`
- Auth: `lib/services/authentication.dart`
- Acces UI: `lib/services/access_control.dart`
- Modeles metier globaux: `lib/model.dart`
- Backend: Firebase Auth, Firestore, Storage, Hosting
- State management: `provider` + `ChangeNotifier`

### Points forts web

- Routing centralise dans `lib/router.dart`.
- Menu centralise avec permissions par module.
- `lib/pointage_redesign/` montre une architecture plus robuste: repositories, providers, modeles, pagination, cache, widgets.
- Module `error_logs` deja utile pour diagnostiquer les erreurs de pointage.
- Firebase Hosting configure en SPA avec rewrite vers `index.html`.

### Risques web

1. Beaucoup de routes utilisent `state.extra as Type`.

   Risque: sur refresh web, deep link, ouverture directe d'une URL, ou navigation depuis un favori, `state.extra` est absent. La page casse parce que l'objet Dart n'existe que pendant la navigation en memoire.

2. Plusieurs ecrans historiques appellent Firestore directement.

   Risque: cache, pagination, erreurs, retries, tests et regles metier sont difficiles a uniformiser.

3. `AuthService.currentManager` est un etat global statique.

   Risque: comportement fragile apres refresh, logout, changement de profil, tests, et chargement asynchrone des permissions.

4. `lib/model.dart` concentre trop de modeles.

   Risque: couplage fort entre domaines, evolution lente, parsing fragile, tests difficiles.

5. Tests insuffisants.

   Le test actuel est encore le test compteur Flutter par defaut et ne valide pas l'application reelle.

6. Encodage texte a surveiller.

   Quelques chaines affichent des caracteres corrompus, par exemple `Age` qui apparait mal encode dans certains fichiers.

## Etat du repo mobile

### Architecture observee

- Entree: `lib/main.dart`
- Pas de router central equivalent a GoRouter; navigation surtout via `Navigator.push`.
- Auth: `lib/services/authentication.dart`
- Cache local: `lib/services/local_storage/database_helper.dart`
- Queue offline: `lib/services/local_storage/offline_queue.dart`
- Sync pointage: `lib/services/offline/offline_pointing_service.dart`
- GPS: `lib/services/gps/`
- Background tracking: `lib/services/background_tracking_config_service.dart` et `lib/supervisor/background_locaion.dart`
- Config backoffice mobile: `lib/services/mobile_config_service.dart`
- Logs erreurs: `lib/services/error_logging_service.dart`
- Providers: `lib/services/providers/`

### Points forts mobile

- Le mode offline est deja pense: cache superviseur, sites, agents, pointages, queue Hive.
- La synchronisation gere plusieurs cas sensibles: pointages en attente, photos locales, upload Firebase Storage, statut de sync.
- Le GPS a une couche dediee avec cache, qualite, source de position et metadata.
- Les logs d'erreur ont deja ete enrichis avec contexte GPS/background tracker.
- `app_config/global` permet de piloter certains comportements depuis Firebase.
- Shorebird/update est deja present pour les mises a jour terrain.
- Il existe des tests GPS (`test/services/gps/...`), ce qui est une bonne base.

### Risques mobile

1. `lib/supervisor/home/new_home.dart` est tres gros.

   Environ 1900 lignes. C'est probablement une page centrale avec UI, navigation, sync, et logique metier. Risque eleve de regression lors d'une grosse mise a jour.

2. Il existe plusieurs couches offline en parallele.

   On voit `lib/offline_services/` et `lib/services/offline/`, plus `lib/services/providers/offline_data_service.dart`. Risque de duplication ou de comportements divergents.

3. La queue offline stocke des maps dynamiques.

   Risque: schemas implicites, corruption Hive, migrations difficiles, erreurs silencieuses.

4. Pointage offline-first.

   `OfflinePointingService.pointSite` sauvegarde localement et queue toujours le pointage. C'est probablement voulu pour fiabiliser le terrain, mais la grosse mise a jour doit clarifier la politique: online direct, offline only, ou offline-first avec sync systematique.

5. GPS actuellement non bloquant dans certains cas.

   `GpsService.getPositionForCheckIn` peut retourner une source `unavailable` sans position apres timeout. Il faut verifier que les ecrans de pointage appliquent bien une regle metier claire avant validation.

6. Polling connexion toutes les 3 secondes.

   `ConnectionProvider` lance un probe periodique. Cela peut etre acceptable, mais a surveiller pour batterie, cout reseau et bruit de logs.

7. Auth offline via cache superviseur.

   C'est utile terrain, mais il faut documenter la duree de validite, la politique logout, et le cas d'un superviseur desactive cote backoffice.

8. Tests encore incomplets.

   Le test widget principal est aussi le test compteur par defaut.

9. Changements non commites presents.

   `spasmobile` avait des modifications non commitees lors de l'analyse, notamment autour de background tracking, error logging, queue offline, photo service, home et sync dialog. Il faut eviter de les ecraser.

## Probleme: Firestore appele directement depuis les ecrans historiques

### Pourquoi c'est un risque

Quand un ecran appelle directement Firestore:

- la pagination est souvent ad hoc;
- les erreurs sont gerees differemment selon les pages;
- les retries et timeouts ne sont pas uniformes;
- les tests widget deviennent difficiles;
- le cache local et la sync offline ne peuvent pas etre reutilises proprement;
- la securite UI peut diverger des regles metier.

### Solution proposee

Adopter un flux standard:

`UI -> Provider/Controller -> UseCase/Service metier -> Repository -> DataSource Firebase/local`

Exemple:

- `SitePage` ne parle pas a Firestore.
- `SiteProvider` expose `loadSites`, `refresh`, `deleteSite`, `filter`.
- `SiteRepository` contient les requetes Firebase.
- `LocalSiteCache` gere le cache si necessaire.
- Les erreurs sont converties en exceptions metier ou resultats typiques.

### Migration progressive

1. Ne pas tout migrer d'un coup.
2. Commencer par les flux de la grosse mise a jour.
3. Creer des repositories pour les domaines critiques: pointage, sites, agents, superviseurs, zones, logs.
4. Laisser les anciens ecrans fonctionner, mais interdire d'ajouter de nouvelles requetes Firestore directes dans l'UI.
5. Ajouter des tests sur les repositories et providers.

## Probleme: routes web avec `state.extra as ...`

### Pourquoi ca casse

`state.extra` transporte un objet Dart uniquement pendant une navigation interne.

Ca casse ou devient fragile dans ces cas:

- refresh navigateur;
- ouverture directe d'une URL;
- lien partage;
- retour navigateur apres redemarrage;
- navigation depuis un favori;
- restauration d'onglet;
- route appelee sans objet `extra`.

Exemple fragile:

`/agents/dossier` attend `state.extra as String`.

Si l'utilisateur ouvre directement `/agents/dossier`, l'objet extra n'existe pas.

### Solution proposee

Les routes doivent porter une identite stable dans l'URL.

Bon pattern:

- `/agents/:agentCode`
- `/agents/:agentCode/documents`
- `/sites/:siteId/edit`
- `/superviseurs/:supervisorId/detail`
- `/errorlogs/:errorLogId`

La page charge ensuite les donnees depuis un repository avec l'id/code de l'URL.

### Utilisation acceptable de `state.extra`

`state.extra` peut rester utile pour accelerer l'affichage:

- passer un objet deja charge pour pre-remplir l'ecran;
- eviter un spinner court;
- transporter un contexte UI non critique.

Mais la page doit toujours avoir un fallback:

1. lire `id` ou `code` dans l'URL;
2. si `extra` existe, l'utiliser comme donnees initiales;
3. sinon charger depuis Firestore;
4. si l'id est invalide, afficher une page d'erreur metier claire.

### Migration progressive GoRouter

1. Ajouter les nouvelles routes parametrees sans supprimer les anciennes.
2. Modifier les boutons/liens pour naviguer vers les nouvelles routes.
3. Ajouter des redirects des anciennes routes si possible.
4. Supprimer les casts obligatoires `state.extra as Type`.
5. Ajouter un test de routing: ouverture directe de chaque route critique.

### Cas mobile

Sur mobile, le risque deep link est moins central si l'application n'utilise pas de liens entrants. Mais `Navigator.push` avec objets complets garde un risque apres restauration d'etat ou refactor.

Pour les flux critiques mobile, preferer:

- passer un id/code stable;
- recharger depuis cache local ou repository;
- utiliser l'objet passe uniquement comme seed optionnel.

## Probleme: contrainte SDK Dart

### Constat

Les deux `pubspec.yaml` indiquent:

`sdk: ">=2.18.6 <3.0.0"`

Mais les deux `pubspec.lock` indiquent:

`dart: ">=3.9.0 <4.0.0"`

`flutter: ">=3.35.0"`

Il y a donc une incoherence entre la contrainte declaree et les dependances verrouillees.

### Pourquoi la contrainte existe probablement

Elle vient probablement de l'epoque initiale du projet, quand Flutter/Dart 2.18 etait la base. Elle a ete conservee par inertie pendant que les dependances et le lockfile ont evolue.

### Pourquoi c'est dangereux

- `flutter pub get` peut refuser la resolution selon la version de Flutter/Dart utilisee.
- Les developpeurs peuvent croire que le projet supporte Dart 2, alors que le lockfile exige Dart 3.9.
- Les CI/builds peuvent etre non reproductibles.
- Certaines dependances recentes ne supportent plus Dart 2.

### Solution proposee

Ne pas changer au hasard. Faire une migration controlee:

1. Identifier la version Flutter reellement utilisee pour build/deploy.
2. Aligner `pubspec.yaml` avec le lockfile si c'est bien la version cible.
3. Exemple probable si Flutter 3.35 est la cible:

   `sdk: ">=3.9.0 <4.0.0"`

4. Lancer:

   - `flutter pub get`
   - `flutter analyze`
   - `flutter test`
   - build web/mobile selon repo

5. Si trop d'erreurs apparaissent, choisir une cible intermediaire et regenerer proprement le lockfile.

### Decision a prendre

Choisir une version Flutter/Dart cible commune pour web et mobile avant la grosse mise a jour.

## Tests et verification

### Etat actuel

- Les tests widget principaux sont des tests compteur par defaut.
- Le mobile a quelques tests GPS utiles.
- L'analyse statique n'a pas ete lancee dans cette passe, car l'outil Flutter/Dart local s'est bloque lors d'une verification de version.

### Minimum recommande avant grosse mise a jour

1. Remplacer le test compteur web.
2. Remplacer le test compteur mobile.
3. Ajouter des tests sur:

   - auth offline;
   - queue offline;
   - pointage offline puis sync;
   - GPS timeout/unavailable/cache;
   - routing web direct par URL;
   - permissions UI par profil.

## Priorites proposees

### Priorite 1: stabiliser la base technique

- Aligner SDK `pubspec.yaml` et `pubspec.lock`.
- Valider `flutter analyze` et `flutter test`.
- Documenter la version Flutter officielle du projet.
- Corriger les tests compteur.

### Priorite 2: securiser les flux critiques

- Pointage site mobile.
- GPS et logs d'erreur.
- Sync offline.
- Routes web de detail/edit.
- Auth et permissions.

### Priorite 3: preparer la refonte progressive

- Introduire repositories et providers sur les modules touches.
- Retirer Firestore direct de l'UI sur les nouveaux travaux.
- Decouper les gros fichiers.
- Creer des contrats de donnees communs web/mobile quand necessaire.

### Priorite 4: observabilite et pilotage

- Continuer la logique `app_config/global`.
- Ajouter des flags de configuration pour comportements sensibles.
- Rendre les erreurs terrain visibles cote backoffice.
- Garder une politique claire de logs sans bruit excessif.

## Decisions ouvertes

1. Quelle version Flutter/Dart devient la version officielle?
2. Est-ce que le mobile doit rester offline-first pour tous les pointages, meme en ligne?
3. Quelle duree maximale accepte-t-on pour une position GPS cachee?
4. Quelle politique si un superviseur est desactive cote backoffice mais possede un cache offline valide?
5. Faut-il partager une librairie de modeles entre web et mobile?
6. Quels modules entrent dans la grosse mise a jour en premier?
7. Le backoffice doit-il exposer plus de configuration mobile via `app_config/global`?

## Conclusion

Le projet a deja les briques necessaires pour evoluer proprement: providers, repositories dans certains modules, offline queue, logs, cache, config pilotable. La grosse mise a jour doit surtout eviter de renforcer les anciens patterns.

La direction recommandee est progressive:

- corriger les incoherences SDK/tests;
- securiser routing web et flux offline mobile;
- utiliser repositories/providers pour les nouveaux changements;
- decouper les gros fichiers seulement quand ils sont touches;
- garder les changements critiques pilotables et observables.
