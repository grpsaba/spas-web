# Prompt pour Opus

Tu es expert Flutter en design produit et en performance. Refonds réellement l’UI/UX du module « Bons de mise en place » sur le web (`C:\Users\hp\Documents\spas\main\spas-web`) et le mobile (`C:\Users\hp\Documents\spas\main\spasmobile`), principalement dans `lib/site_installation/`.

Commence par lire les instructions locales et examiner les écrans actuels. Propose un parcours sobre, cohérent, professionnel et rapide : liste et filtres, création par étapes, sélection recherchable des équipements, détail, suivi et aperçu PDF. Clarifie les statuts et les actions ; réduis la densité et les clics inutiles. Soigne les petits téléphones, le clavier ouvert, les erreurs, le chargement et le hors connexion.

Préserve les règles métier existantes : étapes obligatoires bloquantes, exceptions GPS/deuxième superviseur, agents en texte libre, catalogue commun avec saisie libre, numérotation atomique à la validation, permissions, brouillons hors connexion et suppression avant transmission, finalisation web après retour signé, génération PDF existante et création directe de site. Aucune fonction serveur. Consulte `docs/bons-mise-en-place.md` pour les détails.

Mesure les lenteurs en mode profile avant/après : frames, reconstructions, listes, accès Firestore et génération PDF. Corrige les causes observées, conserve les caches et évite les traitements lourds à chaque frappe. Vérifie visuellement à 320/390 px et sur grand écran, puis exécute les analyses et tests pertinents. Signale les limites de mesure.

Travaille sur les branches actuelles, préserve toutes les modifications existantes, notamment les pointages et la géolocalisation mobiles. Implémente et vérifie le résultat, sans déploiement.
