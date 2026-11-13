# Bons de mise en place

## Parcours

La collection `siteInstallationOrders` conserve les fiches. Un brouillon ne crée ni compte, ni site, ni agent, ni matériel affecté.

| Statut | Action suivante |
|---|---|
| `draft` | L’initiateur complète puis transmet. |
| `submitted` | Le responsable corrige directement, renvoie avec un commentaire, ou valide. |
| `changesRequested` | L’initiateur corrige puis transmet à nouveau. |
| `approved` | Impression du bon, signature SABA et remise physique. |
| `awaitingSignature` | Le client signe ; le document revient au bureau. |
| `signedReturned` | Le responsable web confirme les données du compte et finalise. |
| `finalized` | Le site est créé actif. La fiche est conservée avec son historique. |

Le numéro du bon est attribué automatiquement à sa première validation par le responsable. La photo ou le PDF signé reste facultatif. La confirmation du retour signé et la finalisation sont deux actions du responsable web. La création directe de site existante reste disponible.

## Numérotation commune

Un seul compteur est partagé par toutes les sociétés et prestations : `installationOrderCounters/global`. Il contient `lastNumber` (entier), `lastOrderId` (identifiant du dernier bon numéroté, vide à l’initialisation), `updatedBy` et `updatedAt`.

Avant la première validation, un administrateur utilise « Initialiser le compteur » dans la liste web des bons et renseigne **le dernier numéro réellement utilisé**, en tenant compte des anciens bons manuels et de toute fiche déjà numérotée. Exemple de format uniquement : si le dernier numéro était `31502`, le prochain serait `31503`. Aucune valeur de départ réelle n’est préremplie ni enregistrée par cette implémentation. Les brouillons et transmissions restent disponibles sans compteur ; la validation explique qu’il faut d’abord l’initialiser.

La transition `submitted → approved` lit le compteur et la fiche dans une transaction Firestore, incrémente le compteur et inscrit le numéro sur la fiche, avec le statut et l’événement d’historique. Deux responsables qui valident simultanément obtiennent des numéros distincts ; Firestore relance la transaction en conflit. Une validation invalide ou abandonnée ne consomme aucun numéro. La validation nécessite une connexion. Le numéro apparaît ensuite dans la liste, la fiche mobile/web et le bon imprimé existant.

Le numéro est définitif : aucune saisie manuelle sur les fiches, aucune remise à zéro, aucune réutilisation. Une correction suivie d’une nouvelle validation conserve le numéro initial et ne touche pas au compteur. Les anciennes fiches déjà numérotées conservent également leur valeur. Le compteur ne peut être initialisé qu’une fois par un administrateur et ensuite ne peut évoluer que de +1, avec la première validation correspondante. Les règles vérifient dans les deux sens l’écriture atomique de la fiche et du compteur. Aucune fonction serveur n’est utilisée.

Les noms, types et contacts des agents sont des textes libres. Le catalogue `categorieTools` est commun à toutes les sociétés et filtré par prestation. Les anciens équipements sans `tenantId` ou avec seulement `department.id`/`department.label` sont pris en charge sans migration. Les équipements se sélectionnent avec une quantité. La saisie libre affiche un rappel et un bouton de création dans le catalogue. Cette création exige une connexion ; la désignation libre et la quantité restent utilisables dans le brouillon hors connexion.

Dès la transmission initiale, tous les champs sont obligatoires : site, client, adresse, téléphone du contact, prestation, au moins un agent avec nom/type/contact, au moins un équipement avec désignation/quantité positive, zone, premier superviseur, effectif, rondes, date du contrat et type de pointage. Le deuxième superviseur et les coordonnées GPS restent facultatifs. Si des coordonnées sont saisies, elles doivent former une paire valide. Le numéro du bon reste automatique à la validation. Les brouillons restent enregistrables incomplets, y compris hors connexion ; les erreurs de transmission ramènent à la section à compléter. En l’absence de GPS, le site est créé avec `latLng: null`.

## Web et droits

La liste est le bureau de gestion des demandes. « Tous les dossiers » présente le périmètre autorisé ; « Mes demandes » isole celles initiées par l’utilisateur connecté ; « À traiter » regroupe les demandes à vérifier et les retours signés à finaliser pour le responsable. Les compteurs et le filtre de statut permettent de retrouver les étapes intermédiaires. « Initier une demande » ouvre un nouveau brouillon.

La fiche affiche le parcours, la prochaine étape et une barre d’actions. La saisie est répartie entre « Site & client », « Agents », « Équipements » et « Organisation ». Les onglets « Bon signé » et « Échanges & historique » séparent le document et les discussions des données du site. Les demandes transmises sont présentées en lecture ; le responsable peut modifier celles à vérifier.

Route `/bons-mise-en-place`, module `BON_MISE_EN_PLACE` : `view`, `add`, `validation`, `print`. Les droits sont désactivés par défaut pour les profils existants ; l’administrateur conserve son accès. Le périmètre société/département est appliqué. Un initiateur peut modifier ses brouillons et fiches à corriger ; le responsable peut également corriger une fiche transmise.

L’éditeur de profils écrit `Profils/{nom}.installationAccess`, projection des quatre droits utilisée par les règles. Enregistrer les droits du nouveau module dans cet éditeur avant d’ouvrir l’accès aux responsables. Les règles existantes doivent protéger l’écriture des profils et des affectations de managers ; un utilisateur ne doit pas pouvoir s’attribuer ses propres permissions.

## Mobile et hors connexion

Accès « Mes mises en place » depuis les accueils superviseur et chef de zone. Les agents portail sont exclus. Chaque utilisateur suit uniquement ses fiches. La prestation vient de son département.

Le bouton « Nouvelle demande » ouvre la saisie guidée. « Transmettre au bureau » envoie la demande ou la met en attente si le réseau est indisponible. L’onglet « Suivi » regroupe les commentaires et l’historique ; « Bon signé » permet de joindre une photo. Les cartes de la liste distinguent le statut du dossier et son état de synchronisation.

Les saisies sont sauvegardées dans Hive après une courte pause de frappe, lors d’un retour et lors du passage de l’application en arrière-plan. Les fiches, commentaires en attente, listes de référence et historiques sont mis en cache par société et utilisateur. La transmission peut être mise en attente hors connexion. La synchronisation se fait au retour de connexion, périodiquement lorsque l’accueil est ouvert, et manuellement depuis les fiches.

La version (`revision`) empêche un écrasement silencieux. En cas de conflit, la saisie locale reste conservée ; reprendre la version du bureau garde une copie locale consultable pour reporter les informations utiles. Une nouvelle saisie pendant un envoi reste en attente après l’accusé de réception. Les identifiants d’envoi et de commentaire rendent les reprises idempotentes.

Une première synchronisation en ligne est nécessaire pour disposer du catalogue et des listes de zones/superviseurs hors connexion. Les photos mobiles et les PDF/photos web demandent une connexion. Les photos mobiles viennent de l’appareil photo ou de la galerie. Aucune validation ni finalisation n’est exposée sur mobile.

## Finalisation sans fonction serveur

Le web utilise une application Firebase secondaire pour créer le compte Auth du site, puis une transaction Firestore écrit `Sites/{uid}` avec `actif: true` et finalise la fiche. La session du responsable est conservée. La transaction relit la fiche, sa version, la zone et les superviseurs ; deux tentatives concurrentes ne peuvent pas créer deux sites pour la même fiche.

Auth et Firestore ne partagent pas de transaction. Si le réseau coupe après la création du compte, le navigateur conserve uniquement l’UID et l’email pour permettre une reprise avec le même email et mot de passe. Aucun mot de passe n’est enregistré dans Firestore ou dans ce stockage de reprise. Si un autre responsable a déjà finalisé, le compte supplémentaire de la tentative perdante est supprimé. En cas d’échec avant finalisation, reprendre depuis le même navigateur ; ne pas effacer ses données avant cette reprise. Aucun compte réel n’est créé par les tests.

## Règles et mise en service

Les fichiers `security/site-installation.firestore.rules` et `security/site-installation.storage.rules` sont des politiques isolées de test et des bases de fusion. Les règles actuellement déployées ne sont pas présentes dans ce dépôt. **Ne pas les remplacer intégralement par ces fichiers**, qui ne donnent aucun accès aux autres modules. Aucun changement de règles ni déploiement n’est effectué par cette implémentation.

1. Récupérer les règles réellement déployées et y fusionner les fonctions et règles du module. Vérifier les règles génériques existantes : les autorisations Firestore s’additionnent ; un ancien `allow write: if true` contournerait les contrôles du module.
2. Pour `Sites`, conserver la règle de création directe sur les documents **sans** `installationOrderId` et utiliser `bmpsSiteCreate` pour les documents portant ce marqueur. La création du site et la finalisation doivent être autorisées ensemble dans la transaction.
3. Conserver les droits existants de lecture des zones et superviseurs dans le périmètre de la société. Fusionner `bmpsCatalogRead` pour autoriser la lecture du catalogue commun aux utilisateurs du module et aux superviseurs/chefs de zone actifs, y compris les anciens documents sans société ni identifiant de prestation normalisé. Le filtrage de prestation normalise les anciens formats dans l’application. Conserver la création rapide sans autoriser l’écrasement d’une entrée existante. Aucune migration des données en production n’est exécutée automatiquement.
4. Fusionner la politique Storage pour `site-installation-orders/{tenant}/{fiche}/{fichier}`. Une autorisation d’envoi temporaire est créée dans `siteInstallationOrders/{id}/uploads/{filename}` après contrôle des droits Firestore. Elle expire après 15 minutes. Storage utilise au plus deux lectures Firestore par évaluation. Les scans sont limités à 10 Mo, JPG/PNG/PDF. Les URL de téléchargement sont enregistrées sur la fiche protégée.
5. Fusionner aussi les règles de `installationOrderCounters/global`, en supprimant toute autorisation générique qui permettrait d’écraser le compteur ou le numéro d’une fiche. Enregistrer les droits des profils, déployer les règles fusionnées, puis publier les applications. Initialiser ensuite une seule fois le compteur avec le dernier numéro confirmé. Aucune Cloud Function n’est nécessaire.
6. Vérifier avec deux comptes mobiles et un responsable : brouillon hors ligne, transmission après reconnexion, demande de correction, validation, impression, remise, retour signé sans pièce jointe puis création d’un seul site actif. Vérifier aussi les refus d’accès entre sociétés et départements.

## Vérifications locales

Web : `flutter test test/site_installation_test.dart test/site_installation_ui_test.dart test/site_installation_numbering_test.dart`, `flutter analyze lib/site_installation test/site_installation_test.dart test/site_installation_ui_test.dart test/site_installation_numbering_test.dart lib/services/profil.dart`, `flutter build web --output build/site-installation-check`. Les tests d’interface vérifient les vues, la recherche, la conservation de la saisie entre étapes, les petits écrans et l’initialisation du compteur.

Mobile : `flutter test test/site_installation_offline_test.dart`, `flutter analyze lib/site_installation`.

Sécurité : démarrer l’émulateur Firestore sur `127.0.0.1:8188` pour le projet fictif `demo-spas-installation`, puis `node --test security/test-installation.mjs`. Pour inclure les contrôles des fichiers, démarrer aussi Storage sur `127.0.0.1:9298` avec les règles fournies et lancer en PowerShell `$env:TEST_STORAGE = '1'` puis `node --test security/test-installation.mjs`. Le test charge les règles Firestore et réinitialise uniquement ces émulateurs. Il vérifie les droits, commentaires, transitions, conflits, autorisations temporaires de pièce jointe, initialisation unique, attribution atomique des numéros, concurrence entre sociétés, corrections sans renumérotation et finalisation atomique. Il n’utilise aucun identifiant de production.
