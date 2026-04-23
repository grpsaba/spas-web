# Plan d’amélioration — `AgentList`

## Objectif

Refondre la page `lib/agent/agent_list.dart` pour :

- améliorer nettement l’UI/UX
- réduire les freezes quand le volume de données est important
- sortir les traitements lourds du rendu UI
- remplacer l’approche temps réel par une récupération paginée plus adaptée
- ajouter un filtre par département
- rendre les filtres plus clairs, plus robustes et plus agréables à utiliser

---

## 1. Constats sur l’implémentation actuelle

## 1.1 Problèmes UI/UX

### En-tête trop dense
L’en-tête mélange dans une seule ligne :

- champ de recherche
- filtres rapides par type (`FIXE`, `POINT ZERO`, `RONDIER`)
- filtre actif/inactif
- actions d’ajout/import/badge/impression

Conséquences :

- lecture difficile
- hiérarchie visuelle faible
- peu scalable si on ajoute d’autres filtres
- mauvais comportement probable sur écrans moyens ou petits

### Filtres peu explicites
Les chips actuelles :

- ressemblent à des boutons d’action
- ne montrent pas clairement l’état sélectionné
- ne permettent pas de comprendre facilement les filtres actifs
- ne montrent pas de reset global

### Incohérence du comportement métier
Actuellement, les boutons comme `RONDIER` modifient seulement `_keyword`, ce qui revient à faire une recherche textuelle et non un vrai filtre structuré sur `typeAgent`.

Conséquences :

- résultats inattendus
- perte de confiance utilisateur
- sensation que le filtre “ne marche pas bien”

### Manque de filtres structurés
Il manque au minimum :

- filtre par département
- filtre par type d’agent réel
- réinitialisation visible des filtres
- affichage du nombre de résultats

---

## 1.2 Problèmes de performance

### Usage d’un `StreamBuilder` sur toute la collection
La page écoute en temps réel l’ensemble de la collection `Agents`.

Conséquences :

- gros coût mémoire
- gros coût de parsing
- rebuilds complets inutiles
- peu adapté à une page de listing volumineux

### Parsing lourd dans le `build`
Le flux actuel fait :

- lecture snapshot
- `jsonEncode`
- `jsonDecode`
- `Agent.fromJson`
- filtrage actif/inactif

directement dans le `build`.

Conséquences :

- surcharge CPU dans le thread UI
- freezes visibles
- perte de fluidité

### Filtrage lourd dans `DataTableSource.getRow`
Le pire point actuel est que `getRow()` :

- refiltre `data`
- modifie `data`
- recalcule `dataForPrint`
- exécute des logs

alors que `getRow()` devrait seulement construire une ligne.

Conséquences :

- coût répété à chaque génération de ligne
- pagination incohérente
- résultats instables
- complexité inutile

### Données globales partagées via `static`
`_DataSource.dataForPrint` est statique.

Conséquences :

- effet de bord
- état peu fiable
- couplage fort avec le rendu

---

## 2. Vision cible

La page doit devenir un écran de gestion moderne composé de **4 zones** :

1. **Barre supérieure d’actions**
   - titre
   - compteur de résultats
   - actions principales (`Ajouter`, `Importer`, `Exporter`, `QR`, `Imprimer`)

2. **Panneau de filtres**
   - recherche texte
   - statut actif/inactif
   - type d’agent
   - département
   - bouton “Réinitialiser”

3. **Table de résultats**
   - liste paginée
   - affichage stable
   - pas de calculs lourds pendant le rendu

4. **État de chargement / erreur / vide**
   - skeleton ou loader moderne
   - message si aucun résultat
   - message d’erreur exploitable

---

## 3. Refactor UX proposé

## 3.1 Repenser l’en-tête

### Structure recommandée
Au lieu d’une seule `Row`, faire :

- une `Column`
- avec une première ligne pour le titre et les actions
- une seconde section dédiée aux filtres

### Exemple de structure UX

- Ligne 1 :
  - `Gestion des agents`
  - `X résultats`
  - boutons d’action à droite

- Ligne 2 :
  - champ recherche
  - sélecteur statut
  - sélecteur type
  - sélecteur département
  - bouton reset

### Bénéfices
- meilleure lisibilité
- logique métier plus claire
- plus extensible
- responsive plus simple

---

## 3.2 Remplacer les chips actuelles par de vrais filtres

### Problème des chips actuelles
Les chips `Fixe`, `Point Zéro`, `Rondier` sont actuellement des raccourcis de texte.

### Solution recommandée
Utiliser un composant de filtre sélectionnable clair, par exemple :

- `SegmentedButton`
- `ChoiceChip`
- `FilterChip`
- ou un `DropdownButtonFormField` selon l’espace

### Proposition concrète
Créer un filtre structuré `typeAgent` :

- `Tous`
- `Fixe`
- `Point Zéro`
- `Rondier`

Le filtre agit sur la donnée métier, pas sur une chaîne de recherche.

### Rendu souhaité
Le filtre sélectionné doit être :

- visuellement actif
- désactivable
- persistant pendant la session d’écran

---

## 3.3 Ajouter un filtre par département

### Besoin fonctionnel
Permettre à l’utilisateur de filtrer les agents selon leur département.

### Composant recommandé
Un `DropdownButtonFormField<Department>` ou un composant custom plus moderne.

### Options minimales
- `Tous les départements`
- `Département A`
- `Département B`
- etc.

### Comportement
Le filtre doit agir sur :

- `agent.department?.label`
- ou mieux sur un identifiant stable si disponible

### Important
La liste des départements doit être chargée une seule fois, séparément du listing agents.

---

## 3.4 Revoir le filtre actif/inactif

### Problème actuel
Le chip actif/inactif contient une `Checkbox` dans un `Chip`, ce qui donne une UX assez confuse.

### Solution recommandée
Utiliser un contrôle plus clair :

- `SegmentedButton` avec :
  - `Actifs`
  - `Inactifs`
  - `Tous` (optionnel mais recommandé)

ou

- un `DropdownButton` simple

### Pourquoi ajouter `Tous`
Très utile pour :
- audit
- export global
- usage back-office

---

## 3.5 Ajouter un bouton “Réinitialiser les filtres”
Ce bouton doit remettre à zéro :

- recherche texte
- filtre type
- filtre département
- filtre statut
- pagination éventuelle

Bénéfices :
- UX claire
- évite les états de filtre “coincés”
- facilite la compréhension des résultats

---

## 3.6 Afficher le résumé des filtres actifs
Ajouter une zone légère sous les filtres :

- `234 agents trouvés`
- `Type : Rondier`
- `Département : Logistique`
- `Statut : Actif`

Ou sous forme de petites pills de résumé.

---

## 4. Refonte performance proposée

## 4.1 Remplacer le `StreamBuilder` par une récupération paginée

### Recommandation
Pour cette page, utiliser un chargement paginé avec `Future` ou repository paginé au lieu d’un flux temps réel global.

### Pourquoi
Une liste d’agents administrative :

- n’a pas besoin d’être temps réel
- bénéficie plus d’une pagination stable
- doit éviter de recharger toute la collection en continu

### Stratégie recommandée
Créer une API de type :

- `fetchAgentsPage(...)`
- avec :
  - `limit`
  - `startAfterDocument`
  - filtres serveur si possible
  - tri stable

---

## 4.2 Déplacer les filtres vers la couche data autant que possible

### À faire côté Firestore
Appliquer côté requête ce qui peut l’être :

- `actif == ...`
- `typeAgent.label == ...` si stable
- `department.label == ...` ou idéalement `department.id`
- `limit(...)`

### À garder côté client seulement si nécessaire
La recherche texte libre sur plusieurs champs peut rester côté client dans un premier temps, mais seulement sur **la page courante chargée** ou sur un dataset limité.

### Idéal à moyen terme
Prévoir une stratégie de recherche plus scalable :

- index de recherche
- champ de recherche normalisé
- ou moteur dédié si nécessaire

---

## 4.3 Supprimer tout filtrage depuis `getRow()`
`DataTableSource.getRow()` ne doit plus :

- recalculer `data`
- filtrer
- logger
- muter `dataForPrint`

### `getRow()` doit seulement :
- lire la liste déjà filtrée
- retourner la ligne correspondante à l’index

C’est une priorité absolue.

---

## 4.4 Calculer la liste filtrée une seule fois par changement d’état
La liste affichée doit être calculée :

- après chargement des données
- ou après changement d’un filtre
- pas au moment du rendu ligne par ligne

### Approche recommandée
Conserver séparément :

- `allAgents`
- `filteredAgents`
- `selectedDepartment`
- `selectedType`
- `selectedStatus`
- `searchQuery`

Puis recalculer `filteredAgents` dans une méthode dédiée :

- `_applyFilters()`

---

## 4.5 Éviter `jsonEncode/jsonDecode` inutiles
Actuellement, le mapping Firestore → modèle passe par :

- `jsonEncode`
- `jsonDecode`

C’est coûteux.

### Recommandation
Utiliser directement :

- `Map<String, dynamic>.from(e.data() as Map)`

ou des converters Firestore si possible.

### Bénéfice
- moins de CPU
- moins d’allocations mémoire
- meilleur temps de réponse UI

---

## 4.6 Préparer un repository dédié à la liste agents
Créer une couche dédiée, par exemple :

- `AgentListRepository`
- ou enrichir `AgentService`

Responsabilités :

- pagination
- filtres
- chargement des pages
- prochain curseur
- refresh

Cela évite que la page UI fasse :
- récupération
- parsing
- filtrage
- état métier

---

## 5. Nouvelle architecture recommandée pour la page

## 5.1 État local ou provider dédié
Créer un state manager léger pour la page, par exemple :

- `AgentListController`
- `AgentListProvider`

Il doit contenir :

- `isLoading`
- `isLoadingMore`
- `allAgents` ou `currentPageAgents`
- `filteredAgents`
- `searchQuery`
- `selectedStatus`
- `selectedType`
- `selectedDepartment`
- `rowsPerPage`
- `errorMessage`

---

## 5.2 Découpage UI en widgets
Découper la page en widgets dédiés :

- `AgentListHeader`
- `AgentFilterBar`
- `AgentTableSection`
- `AgentListActions`
- `AgentStatusChip`

### Bénéfices
- meilleure lisibilité
- meilleure testabilité
- rebuilds plus ciblés
- maintenance plus simple

---

## 6. Plan concret d’évolution par phases

## Phase 1 — Stabilisation rapide
Objectif : supprimer les sources de freeze immédiates.

### À faire
- retirer le filtrage de `getRow()`
- supprimer les `print`
- rendre `AgentStatut.agent` final
- calculer la liste filtrée avant la création du `DataSource`
- conserver une seule liste filtrée pour affichage et export

### Résultat attendu
- moins de recalculs
- table plus stable
- baisse du coût CPU immédiat

---

## Phase 2 — Refonte des filtres
Objectif : UX plus claire et plus fiable.

### À faire
- remplacer les chips “Fixe / Point Zéro / Rondier” par de vrais filtres métier
- ajouter le filtre département
- remplacer le chip actif/inactif par un contrôle plus clair
- ajouter un bouton “Réinitialiser”
- afficher le compteur de résultats

### Résultat attendu
- meilleure compréhension
- comportement cohérent
- design plus moderne

---

## Phase 3 — Refactor data loading
Objectif : réduire massivement la charge au démarrage.

### À faire
- remplacer le `StreamBuilder` par un chargement paginé
- créer une méthode de requête paginée côté service
- ne charger qu’un sous-ensemble de données
- recharger seulement quand les filtres changent

### Résultat attendu
- démarrage plus rapide
- moins de mémoire utilisée
- disparition d’une grande partie des freezes

---

## Phase 4 — Raffinement UX
Objectif : rendre la page plus professionnelle.

### À faire
- skeleton loaders
- état vide travaillé
- messages d’erreur propres
- responsive amélioré
- actions regroupées visuellement
- confirmation visuelle des filtres actifs

---

## 7. Comportement fonctionnel cible des filtres

## Recherche
Recherche texte libre sur :

- code
- prénom
- nom
- téléphone
- site
- département
- type

## Statut
- Tous
- Actifs
- Inactifs

## Type d’agent
- Tous
- Fixe
- Point Zéro
- Rondier

## Département
- Tous
- liste des départements

## Règle de combinaison
Les filtres se combinent avec un `AND` logique :

- statut
- type
- département
- recherche texte

Exemple :
- `Actif`
- `Rondier`
- `Département = X`
- `Recherche = "Ali"`

---

## 8. Design recommandé pour le bloc filtres

## Variante recommandée
Un conteneur visuel de filtre avec :

- fond légèrement contrasté
- coins arrondis
- padding confortable
- séparation nette avec la table

### Organisation possible
- Ligne 1 : recherche
- Ligne 2 : statut / type / département / reset

### Style
- éviter trop de couleurs agressives
- réserver les couleurs fortes aux états sélectionnés
- utiliser une hiérarchie claire entre filtres et actions

---

## 9. Export / impression / badge

## Problème actuel
L’export s’appuie sur une liste statique calculée par le `DataSource`.

## Cible
Les actions d’export doivent utiliser :

- la liste filtrée actuelle
- détenue au niveau de l’état de page
- indépendante du rendu tableau

### Avantages
- fiabilité
- lisibilité
- moins d’effets de bord

---

## 10. Risques techniques à anticiper

- certains filtres Firestore combinés peuvent demander des indexes
- si `department` et `typeAgent` sont stockés comme objets embarqués, les filtres serveur doivent être validés soigneusement
- la recherche texte globale multi-colonnes ne sera pas scalable à très grande échelle sans stratégie dédiée
- il faudra bien synchroniser la pagination avec les filtres

---

## 11. Recommandation de priorité

### Priorité haute
1. sortir le filtrage de `getRow()`
2. enlever le `StreamBuilder`
3. passer à une récupération paginée
4. refaire complètement la barre de filtres
5. ajouter filtre département

### Priorité moyenne
6. centraliser l’état de page
7. découper en widgets dédiés
8. améliorer export/impression

### Priorité basse
9. raffinement visuel avancé
10. animations légères
11. état vide enrichi

---

## 12. Résultat attendu final

Après refonte, la page devra être :

- plus rapide à charger
- plus fluide quand il y a beaucoup d’agents
- plus claire visuellement
- plus facile à utiliser
- plus cohérente métier
- plus simple à maintenir
- prête à supporter les filtres métier réels, dont le département

---

## 13. Proposition de livrable technique suivant

Pour l’implémentation, la meilleure suite serait :

1. créer un nouveau state model pour la page
2. introduire un chargement paginé côté service
3. refondre l’UI des filtres
4. brancher les nouveaux filtres structurés
5. retirer complètement la logique de filtrage depuis `_DataSource.getRow()`

---

## Conclusion

La page actuelle fonctionne, mais elle mélange trop :

- rendu
- chargement
- filtrage
- permissions
- export
- mutations

Le principal chantier n’est pas seulement visuel : il est aussi structurel.

Pour obtenir une vraie amélioration durable, il faut :

- simplifier l’UI
- rendre les filtres explicites
- déplacer les traitements lourds hors du rendu
- charger les données de manière paginée
- ajouter un filtre département réel

C’est cette combinaison qui réglera à la fois :
- le ressenti UX
- la lisibilité
- et les freezes.