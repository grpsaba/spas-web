# Plan multi-pays et reflexion departements

Date: 2026-06-04

Repos concernes:

- Backoffice: `C:\Users\hp\Documents\spas\main\spas-web`
- Mobile: `C:\Users\hp\Documents\spas\main\spasmobile`

Objectif: documenter le plan avant developpement pour supporter plusieurs pays, sans compliquer inutilement l'application, et sans rendre des donnees existantes invisibles.

## Principes valides

1. Ne pas dupliquer Firestore en sous-collections par pays.
2. Garder les collections actuelles.
3. Ajouter un champ top-level d'appartenance pays sur les documents metier.
4. Traiter les documents historiques sans pays comme appartenant au Mali.
5. Filtrer cote serveur, pas cote client, pour eviter les lenteurs et freezes.
6. Ne pas forcer tout de suite une separation stricte par departement.
7. Les pointages doivent porter `tenantId` et `departmentId` en top-level a chaque nouvelle ecriture.

## Terminologie retenue pour le pays

Le champ recommande est:

```txt
tenantId
```

Exemples:

```txt
ml
bf
```

Pourquoi `tenantId` plutot que `countryId`:

- aujourd'hui un tenant correspond a un pays ou une filiale;
- demain il pourrait y avoir plusieurs filiales dans un meme pays;
- le nom reste plus souple sans imposer une architecture compliquee.

La collection de reference sera Firestore:

```txt
tenants/{tenantId}
  id: "ml"
  label: "Mali"
  countryCode: "ML"
  active: true
  pointageMode: "photo"
```

Cette collection sert surtout a alimenter les listes de choix avant connexion mobile et backoffice.

## Mode de pointage par tenant

Decision validee:

```txt
pointageMode
```

est la seule source de verite pour choisir le comportement du pointage site.

Valeurs autorisees:

```txt
photo
geo
```

Le mode `photo` implique:

```txt
photoRequired: true
distanceRequired: false
backgroundTrackingEnabled: false
```

Le mode `geo` implique:

```txt
photoRequired: false
distanceRequired: true
backgroundTrackingEnabled: true
```

On ne stocke donc pas `photoRequired`, `distanceRequired` et `backgroundTrackingEnabled` comme options libres par tenant, afin d'eviter des combinaisons incoherentes.

Exemples:

```txt
tenants/ml
  pointageMode: "photo"

tenants/bf
  pointageMode: "geo"
```

Le document global `app_config/global` peut rester utilise pour les reglages techniques globaux, par exemple `pointingPhotoQuality`. Le demarrage du tracking GPS background doit etre derive du `pointageMode` du tenant connecte.

Regle importante:

- les documents `tenants` servent de reference;
- le `tenantId` d'un tenant ne doit pas etre modifie;
- on ne prevoit pas de fonction backoffice pour modifier l'identifiant d'un tenant existant;
- si un tenant est mal cree, il vaut mieux en creer un nouveau et migrer explicitement les donnees concernees.

## Profils backoffice et acces global

Observation dans le code:

- `Manager.profil` contient un objet `Profil`.
- `ProfilService` utilise `Profils/{profil.name}` comme document.
- `AuthService.authState()` recharge le profil complet avec `ProfilService().one(profileName)`.
- `AccessControl` utilise deja `manager.profil.name` pour donner tous les droits au profil `Administrateur`.

La collection `Profils` contient environ une dizaine de profils, dont:

```txt
Administrateur
Chef des operations
Controleur General
Cordinateur des contrats
Directeur General
Gestion des crises
Poste de controle
REPONSABLE NETTOYAGE
RESPONSABLE NETTOYAGE
Ressources Humains
superviseur PC
```

Regle metier retenue:

```txt
Administrateur
Directeur General
```

peuvent voir toutes les donnees sans filtre pays obligatoire.

Tous les autres profils doivent etre filtres par leur `tenantId`.

Donc il n'est pas necessaire d'ajouter tout de suite un champ du type `tenantIds`.

Approche simple:

- les managers normaux ont `tenantId`;
- le nom du profil determine si le filtre pays est obligatoire;
- `Administrateur` et `Directeur General` peuvent choisir un pays globalement ou sur une page;
- si aucun pays n'est choisi par ces profils globaux, la requete peut etre faite sans filtre tenant, mais avec pagination obligatoire.
- le login backoffice ne doit pas affecter automatiquement un `tenantId` a un manager normal sans pays;
- un manager normal sans `tenantId` doit etre refuse a la connexion et renvoye vers un administrateur.

Donc le contexte utilisateur peut etre:

```txt
Manager
  tenantId: "ml"
  profil: {...}
```

Et la logique applicative:

```txt
si profil Administrateur ou Directeur General:
  si pays selectionne:
    requete avec where("tenantId", isEqualTo: selectedTenantId)
  sinon:
    requete sans filtre tenant, mais seulement sur les pages prevues et avec pagination
sinon:
  requete avec where("tenantId", isEqualTo: currentUser.tenantId)
```

Cette approche colle a l'existant, car les roles sont deja dans `Profils` et le code se base deja sur `profil.name`.

Point a implementer plus tard:

- etendre `AccessControl` pour reconnaitre `Directeur General` comme profil global;
- creer une methode dediee, par exemple `AccessControl.canBypassTenantFilter`;
- ne pas melanger ce droit avec les droits de modules (`view`, `add`, `delete`, etc.).

## Choix pays avant connexion

### Mobile

Avant connexion, l'utilisateur choisit son pays.

Apres Firebase Auth:

1. recuperer `Supervisors/{uid}`;
2. si le document superviseur a deja un `tenantId`, utiliser celui de Firestore;
3. si le pays choisi est different du `tenantId` Firestore, ignorer le choix utilisateur et utiliser la valeur Firestore;
4. si le document n'a pas encore `tenantId`, utiliser le pays choisi pour initialiser/memoriser cette information, avec fallback `ml` pendant la transition;
5. seul un administrateur backoffice pourra reaffecter plus tard un superviseur a un autre tenant.

### Backoffice

Avant connexion, le manager choisit son pays.

Apres Firebase Auth:

1. recuperer `Managers/{uid}`;
2. si le document manager a deja un `tenantId`, utiliser celui de Firestore;
3. si le pays choisi est different du `tenantId` Firestore, ignorer le choix utilisateur et utiliser la valeur Firestore;
4. si le document n'a pas encore `tenantId` et que le profil est normal, refuser la connexion avec un message demandant de contacter un administrateur;
5. si le manager a le profil `Administrateur` ou `Directeur General`, il peut se connecter sans `tenantId`;
6. si le manager a le profil `Administrateur` ou `Directeur General`, il peut ensuite choisir d'afficher un tenant precis ou tous les tenants selon la page.

Le pays choisi avant login ne doit donc pas ecraser un `tenantId` deja existant dans `Managers` ou `Supervisors`.

## Affectation des utilisateurs aux tenants

Le rattachement d'un utilisateur a un pays doit etre explicite depuis le backoffice.

Regles retenues:

- `Administrateur` et `Directeur General` peuvent rester sans `tenantId`;
- un manager normal doit avoir un `tenantId` pour se connecter;
- un superviseur mobile doit avoir un `tenantId` pour etre correctement filtre;
- le login backoffice ne cree pas automatiquement le `tenantId` d'un manager normal;
- les formulaires backoffice `Managers` et `Supervisors` portent le champ pays;
- un administrateur peut affecter ou modifier le pays d'un manager ou d'un superviseur;
- un manager non global ne peut affecter que son propre tenant.
- `Administrateur` et `Directeur General` peuvent appliquer un filtre pays global dans le backoffice.

Effet attendu:

```txt
Manager normal sans tenantId
  -> connexion refusee
  -> message: contacter un administrateur
  -> l'administrateur affecte tenantId depuis le backoffice
```

## Collections concernees par `tenantId`

Le champ `tenantId` doit etre ajoute aux collections principales:

```txt
Managers
Supervisors
Sites
Agents
Zones
ZoneMembers
Tools
Notes
CheckLists
sitePointings
agentPointings
zonePointings
rondierPointings
toolPointings
locationTracker
error_logs
```

Collections de configuration a arbitrer:

```txt
Profils
departments
agentTypes
categorieTools
app_config
agentBulkConfig
```

Pour ces collections, deux options:

1. globales pour tous les pays;
2. filtrees par `tenantId` si chaque pays doit avoir ses propres valeurs.

Recommandation initiale:

- `Profils`: probablement global au debut, sauf si les droits different fortement par pays.
- `departments`: global au debut.
- `agentTypes`: global au debut.
- `categorieTools`: a surveiller, car lie aux departements et checklists.
- `app_config`: peut rester global au debut, mais certains champs mobiles pourraient devenir par pays plus tard.

## Documents historiques sans `tenantId`

Tous les documents historiques doivent etre consideres comme Mali.

Transition:

```txt
tenantId absent => "ml"
```

Mais il ne faut pas rester longtemps avec cette logique dans les requetes, car Firestore ne permet pas une strategie propre et performante du type:

```txt
tenantId == "ml" OU tenantId absent
```

Recommandation:

1. ajouter un fallback dans les modeles pour eviter les crashs;
2. migrer les documents existants par batch pour ajouter `tenantId: "ml"`;
3. ensuite utiliser uniquement des requetes serveur avec `where("tenantId", isEqualTo: ...)`.

Pendant la transition, les regles et la logique de lecture doivent considerer:

```txt
document sans tenantId = document Mali
```

Mais pour les grandes listes, le but reste de migrer rapidement les documents afin d'eviter des requetes speciales trop lourdes.

## Departements: sujet plus delicat

La separation departement ne doit pas etre forcee trop vite.

Observation dans les modeles actuels:

- `Department` contient seulement `label`.
- `Agent` porte deja `department`.
- `Supervisor` porte deja `department`.
- `Note` porte deja `department`.
- `CategorieTool` porte deja `department`.
- `Site` ne porte pas de departement direct.
- `CheckList` ne porte pas de departement direct, mais contient `cattool`, `site` et `supervisor`.
- Les pointages ne portent pas encore de `departmentId` top-level.

Raisons:

- beaucoup de documents historiques n'ont pas cette information;
- ajouter un filtre strict peut rendre invisibles des donnees importantes;
- un meme site peut concerner plusieurs departements;
- exemple: un site peut etre securise par le departement securite et aussi recevoir des agents de nettoyage;
- le departement est deja present dans certains documents, mais pas de facon systematique.

Decision de prudence:

- ne pas activer le filtre departement pour le Mali (`ml`) dans un premier temps;
- le rendre possible pour les nouveaux pays ou les nouvelles donnees lorsque `departmentId` est fiable;
- pour tout tenant different de `ml`, appliquer le filtre departement si le manager connecte a un scope departement;
- continuer a afficher les donnees Mali historiques meme si `departmentId` est absent;
- eviter toute requete qui exclut les documents sans departement tant que la migration departement n'est pas terminee.

## Departement sur un site

Un site ne doit pas forcement avoir un seul `departmentId`.

Meilleur modele potentiel:

```txt
Sites/{siteId}
  tenantId: "ml"
  departmentIds: ["security", "cleaning"]
```

Cela signifie:

- le site existe pour le pays Mali;
- il peut avoir de l'activite securite;
- il peut aussi avoir de l'activite nettoyage.

Ne pas utiliser uniquement:

```txt
departmentId: "security"
```

sur `Sites`, car cela rendrait les sites multi-activites difficiles a representer.

## Departement sur les agents et superviseurs

Ici, un champ simple peut suffire:

```txt
Agents/{agentCode}
  tenantId: "ml"
  departmentId: "security"

Supervisors/{uid}
  tenantId: "ml"
  departmentId: "security"
```

Mais il faut rester prudent:

- certains superviseurs peuvent-ils couvrir plusieurs departements?
- les profils Direction peuvent-ils agir sans etre lies a un departement unique?

Si besoin, on pourra utiliser:

```txt
departmentIds: ["security", "cleaning"]
```

sur les managers ou profils de backoffice.

## Departement sur les pointages

Pour les pointages, il faut ajouter un champ top-level:

```txt
tenantId: "ml"
departmentId: "security"
```

Pourquoi:

- eviter de lire/filtrer dans `site.departmentIds`;
- eviter de dependre du snapshot embarque `site` ou `supervisor`;
- faciliter les requetes serveur;
- faciliter les rapports.

Regle proposee:

- `departmentId` est obligatoire pour toute nouvelle ecriture de pointage, y compris Mali;
- pointage agent: `departmentId` vient de l'agent;
- pointage site: `departmentId` vient du contexte de pointage ou du superviseur;
- checklist outil: `departmentId` vient de la categorie/checklist ou du superviseur;
- note: `departmentId` vient de la note ou du superviseur;
- zone pointage: a arbitrer, selon si les zones sont liees a la securite uniquement.

Important:

- pour `ml`, on ecrit `departmentId`, mais on n'applique pas encore le filtre departement dans le backoffice;
- pour `bf` et les futurs tenants non-`ml`, on peut appliquer le filtre departement des le depart si les donnees sont creees proprement.

## Strategie departement recommandee

Ne pas activer un filtre global departement immediatement.

Phase 1:

- ajouter `tenantId` partout;
- ajouter `departmentId` a chaque nouvelle ecriture quand le contexte le permet, et obligatoirement sur les pointages;
- ne pas masquer les donnees sans `departmentId`.
- ne pas appliquer de filtre departement strict sur `ml`.

Phase 2:

- auditer les donnees existantes;
- identifier les sites multi-departements;
- ajouter `departmentIds` sur `Sites`;
- completer `departmentId` sur `Agents`, `Supervisors`, `Notes`, `CategorieTools`, pointages.

Phase 3:

- activer les filtres departement seulement sur les ecrans ou c'est fiable;
- activer d'abord pour les nouveaux pays ou les donnees deja completees;
- pour Direction, proposer un filtre Securite / Nettoyage;
- eviter d'appliquer ce filtre aux ecrans ou les donnees historiques sont incompletes.

## Requetes serveur

Principe normal:

```txt
query = collection.where("tenantId", isEqualTo: currentTenantId)
```

Puis ajouter les filtres existants:

```txt
where("actif", isEqualTo: true)
where("supervisor.UID", isEqualTo: uid)
where("datetimestamp", isGreaterThanOrEqualTo: start)
where("datetimestamp", isLessThan: end)
```

Pour `Administrateur` et `Directeur General`:

```txt
si pays selectionne:
  where("tenantId", isEqualTo: selectedTenantId)
sinon:
  pas de filtre tenant, mais pagination obligatoire
```

Important:

- eviter les `.get()` complets suivis de `.where()` cote client;
- garder la pagination sur les grandes collections;
- les ecrans qui listent les pointages doivent filtrer par `tenantId` cote serveur.

Regle departement:

```txt
si currentTenantId == "ml":
  pas de filtre departement global pour le moment
sinon:
  appliquer le filtre departement selon le profil/scope du manager
```

## Index Firestore

Aujourd'hui, les indexes sont crees manuellement depuis les liens proposes par Firestore quand une requete echoue avec `failed-precondition`.

C'est acceptable pour avancer rapidement.

Mais il faudra garder une trace des indexes crees, au minimum dans un document, car une migration multi-pays va multiplier les indexes.

Exemples probables:

```txt
sitePointings:
  tenantId + datetimestamp
  tenantId + supervisor.UID + datetimestamp
  tenantId + site.UID + datetimestamp
  tenantId + departmentId + datetimestamp

zonePointings:
  tenantId + datetimestamp
  tenantId + zoneMember.UID + datetimestamp
  tenantId + site.UID + datetimestamp

Agents:
  tenantId + actif + code
  tenantId + departmentId + actif + code

Sites:
  tenantId + actif
  tenantId + departmentIds + actif
```

Note: pour `departmentIds` tableau, Firestore utilise `array-contains` ou `array-contains-any`. Les indexes devront etre crees selon les requetes reelles.

## Firestore Rules

Les rules devront etre mises a jour.

Principe:

- un manager normal ne lit que les documents de son `tenantId`;
- un superviseur mobile ne lit/ecrit que les documents de son `tenantId`;
- pendant la transition, un document sans `tenantId` est accepte comme `ml`;
- les profils `Administrateur` et `Directeur General` peuvent lire plus largement;
- les creations doivent imposer `tenantId`.

Important:

Firestore Rules ne filtrent pas les resultats a la place de la requete.

Donc si une requete utilisateur normal oublie:

```txt
where("tenantId", isEqualTo: currentTenantId)
```

la requete risque d'etre refusee par les rules.

Expression logique a viser dans les rules:

```txt
doc.tenantId == user.tenantId
OU
(doc.tenantId absent ET user.tenantId == "ml")
```

Pour les creations:

```txt
request.resource.data.tenantId doit exister
request.resource.data.departmentId doit exister quand le type de document le permet
```

Le fallback `tenantId absent => ml` sert a lire l'historique, pas a autoriser de nouveaux documents incomplets.

## Migration progressive proposee

### Etape 1: definir les valeurs

Tenants:

```txt
ml = Mali
bf = Burkina Faso
```

Departments:

```txt
security = Securite
cleaning = Nettoyage
direction = Direction
```

Decision confirmee:

- `direction` est un departement de donnees, pas seulement un profil de visibilite.
- les sites multi-departements utilisent `departmentIds`.

### Etape 2: ajouter le pays au contexte utilisateur

Ajouter `tenantId` dans:

```txt
Managers
Supervisors
```

Documents historiques:

```txt
tenantId: "ml"
```

### Etape 3: choix pays avant login

Mobile et backoffice:

- afficher une liste simple de pays actifs;
- memoriser le choix localement;
- apres auth, utiliser le `tenantId` Firestore si le manager/superviseur en possede deja un;
- si aucun `tenantId` n'existe encore dans Firestore, utiliser le pays choisi pour initialiser cette information;
- pour `Administrateur` et `Directeur General`, permettre ensuite un filtre pays global ou par page.

### Etape 4: migration Mali des donnees existantes

Ajouter:

```txt
tenantId: "ml"
```

aux collections principales.

Le plus important:

```txt
Sites
Agents
Supervisors
Managers
sitePointings
zonePointings
agentPointings
Notes
CheckLists
error_logs
```

### Etape 5: modifier les services critiques

Ajouter le filtre tenant dans les services:

```txt
SiteService
AgentService
SupervisorService
PointingSiteService
PointingZoneService
NoteService
ErrorLogProvider
PointageRepository
PointageZoneRepository
```

### Etape 6: ecriture des nouveaux documents

Toute creation doit ecrire:

```txt
tenantId
```

Et pour les documents concernes:

```txt
departmentId
```

Pour les pointages, `departmentId` est obligatoire a l'ecriture.

Pour `ml`, ce champ est ecrit mais ne sert pas encore de filtre backoffice global.

Pour les tenants differents de `ml`, le filtre departement peut etre applique si le manager connecte doit etre limite a son departement.

### Etape 7: departements seulement apres audit

Ne pas activer partout un filtre departement tant que les donnees historiques ne sont pas completees.

Commencer par:

- agents;
- superviseurs;
- notes;
- categories d'outils;
- pointages recents.

Puis seulement:

- sites multi-departements;
- rapports par departement;
- filtres Direction.

## Risques principaux

1. Donnees invisibles si un filtre departement est applique trop tot.
2. Requetes lentes si on garde des `.get()` complets puis filtre client.
3. Indexes nombreux apres ajout de `tenantId`.
4. Pointages historiques sans `tenantId` si la migration n'est pas faite.
5. Incoherence entre objet embarque et champ top-level.
6. Profil global mal defini si la logique `Administrateur` / `Directeur General` n'est pas centralisee.
7. Certaines pages avec provider/cache peuvent devoir relancer explicitement leurs requetes quand le filtre pays global change.

## Index Firestore detectes pendant les tests

Les index ne sont pas tous crees manuellement a l'avance. Pendant les tests, Firestore affiche un lien de creation automatique dans la console quand une requete composite manque d'index.

Premiers index detectes apres ajout de `TenantScope`:

```txt
Collection: sitePointings
Champs:
- tenantId ASC
- datetimestamp ASC
- __name__ ASC

Contexte probable:
- PointingSiteService.all
- pointages site filtres par tenant + plage de date
```

```txt
Collection: Notes
Champs:
- tenantId ASC
- viewed ASC
- date DESC
- __name__ DESC

Contexte:
- NoteService.allNoViewedNote
```

```txt
Collection: agentPointings
Champs:
- tenantId ASC
- date ASC
- __name__ ASC

Contexte:
- PointingAgentService.allByDay
```

Regle pratique:

- cliquer le lien Firebase donne par l'erreur `failed-precondition`;
- attendre que l'index soit actif;
- relancer la page ou la requete;
- ajouter ici les index importants qui reviennent souvent.

Note apres backfill Mali:

- le backfill des documents historiques vers `tenantId: "ml"` a ete execute;
- le choix global `Mali` ne doit plus rester equivalent a une lecture non filtree;
- la prochaine etape code est de rendre `Mali` strictement filtre dans `TenantScope`;
- l'ancien fallback `tenantId absent => ml` reste utile dans les modeles et les rules pendant une courte transition, mais ne doit plus piloter les grandes requetes applicatives.

## Etat apres backfill du 2026-06-05

Backfill execute et confirme termine par l'utilisateur sur les collections metier prioritaires.

Collections confirmees traitees:

```txt
Agents
Zones
ZoneMembers
Tools
Notes
CheckLists
locationTracker
sitePointings
agentPointings
zonePointings
rondierPointings
toolPointings
```

Collections a ne pas traiter automatiquement ou a traiter separement selon besoin:

```txt
Managers
error_logs
```

Notes:

- `Managers` ne doit pas etre backfill automatiquement en `ml`, car l'affectation pays des managers doit rester explicite;
- `error_logs` est maintenant filtre par `TenantScope` cote backoffice; si les logs historiques doivent etre visibles pour les managers normaux, lancer un backfill `tenantId: "ml"` sur cette collection;
- le script `scripts/backfill_tenant_ml.js` inclut maintenant `error_logs` dans ses collections par defaut;
- un dernier dry-run par collection peut servir de controle, mais le blocage principal des donnees invisibles Mali est leve.

## Plan de reprise apres backfill

### Priorite 1: verrouiller le filtrage pays

Etat: fait le 2026-06-05 apres backfill.

1. L'exception temporaire dans `TenantScope` qui rendait `Mali` non filtre pour les profils globaux a ete retiree.
2. Garder la regle simple:

```txt
Administrateur / Directeur General + Tous pays => pas de filtre tenant
Administrateur / Directeur General + Mali => where tenantId == "ml"
Administrateur / Directeur General + Burkina => where tenantId == "bf"
Manager normal => where tenantId == manager.tenantId
```

3. Tester avec:

```txt
Administrateur sans filtre
Administrateur filtre Mali
Manager normal Mali
Manager normal sans tenantId
```

### Priorite 2: verifier les collections critiques

Etat partiel: les lectures directes backoffice identifiees ont ete branchees sur `TenantScope` le 2026-06-05.

Fichiers corriges:

```txt
lib/error_logs/providers/error_log_provider.dart
lib/accueil/providers/site_status_provider.dart
lib/pointage_site/pointage_site_list.dart
lib/zone/zone_site_monthly_pointage.dart
lib/zone/providers/zone_pointage_provider.dart
```

Tester d'abord les ecrans qui lisent beaucoup de donnees:

```txt
Sites
Agents
Notes
CheckLists
Pointages site
Pointages agent
Pointages zone
Dashboard / accueil
```

Objectif:

- confirmer que les donnees Mali reviennent pour un manager normal;
- cliquer les liens d'index Firestore qui apparaissent encore;
- noter les nouveaux index dans ce document.

### Priorite 3: finaliser les ecritures

Etat partiel: la creation bulk d'agents ecrit maintenant le tenant via `TenantScope.applyTenantIdForWrite`.

Verifier que les creations et modifications ecrivent toujours:

```txt
tenantId
```

Et pour les documents concernes:

```txt
departmentId
```

Le point important est de ne plus creer de nouveaux documents metier sans `tenantId`.

### Priorite 4: rules Firestore

Quand les tests backoffice sont stables:

1. renforcer les rules pour obliger le `tenantId` sur les creations;
2. limiter les lectures/ecritures d'un manager normal a son tenant;
3. garder une tolerance courte pour les anciens documents sans `tenantId`;
4. ne pas activer de filtre departement strict pour `ml`.

### Priorite 5: mobile

Appliquer ensuite le meme principe dans `spasmobile`:

```txt
choix pays avant login
lecture Supervisors/{uid}
tenantId Firestore prioritaire
ecritures pointage avec tenantId top-level
departmentId top-level quand disponible
```

Le mobile doit etre traite apres stabilisation backoffice, car les superviseurs et pointages dependent des memes donnees.

## Decisions ouvertes

1. Decider quand activer les filtres departement pour `ml`.
2. Definir les valeurs exactes de `departmentId`: `security`, `cleaning`, `direction` ou variantes francaises.

## Decisions confirmees

1. Priorite: multi-pays d'abord.
2. Champ pays final: `tenantId`.
3. Tenants initiaux: `ml`, `bf`.
4. `tenants` est une collection Firestore.
5. Les profils `Administrateur` et `Directeur General` sont les seuls profils pouvant ne pas filtrer par pays.
6. Les autres profils sont filtres par leur `tenantId`.
7. Le pays choisi au login ne remplace pas un `tenantId` deja present dans `Managers` ou `Supervisors`.
8. Le `tenantId` d'un tenant existant n'est pas modifiable depuis le backoffice.
9. `direction` est un departement de donnees.
10. Les sites multi-departements utilisent `departmentIds`.
11. `departmentId` doit etre ecrit sur les nouveaux documents concernes, notamment tous les pointages.
12. Pour `ml`, on n'applique pas encore le filtre departement global.
13. Pour les tenants differents de `ml`, le filtre departement peut etre applique des le depart.
14. Un manager normal sans `tenantId` ne doit pas recevoir automatiquement `ml` au login.
15. L'affectation `tenantId` des managers et superviseurs se fait depuis le backoffice par un profil autorise.
16. Le filtre pays global admin/DG est applique par les services via `TenantScope` quand un tenant est selectionne.

## Conclusion

La priorite doit etre le multi-pays, pas le filtre departement strict.

Plan recommande:

1. Ajouter `tenantId` proprement.
2. Migrer tout l'existant vers `tenantId: "ml"`.
3. Filtrer serveur par pays.
4. Ajouter `tenantId` top-level aux pointages.
5. Ajouter `departmentId` top-level aux nouveaux documents concernes, obligatoirement aux pointages.
6. Garder la partie departement plus progressive, avec audit, car un site peut appartenir a plusieurs departements et les donnees historiques sont incompletes.
