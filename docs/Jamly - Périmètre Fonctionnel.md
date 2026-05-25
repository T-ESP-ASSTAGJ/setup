# Jamly — Périmètre Fonctionnel

## Fonctionnalités implémentées (PBS)

### Gestion des utilisateurs
- Inscription (email → OTP → profil)
- Connexion / Déconnexion (sans mot de passe)
- Profil utilisateur : photo, bio, username
- Statistiques musicales (via Apple Music, côté client)
- Paramètres de confidentialité
- Paramètres de notifications

### Abonnements
- Suivre / se désabonner
- Liste des abonnements / abonnés

### Publication de contenu
- Création d'un post (musique obligatoire, deux images, description, localisation)
- Modification d'un post (description, localisation — pas la musique)
- Suppression d'un post

### Fil d'actualité
- Feed privé (abonnements, ordre chronologique inversé)
- Feed public (algorithme de pertinence pour les utilisateurs authentifiés)
- Scroll infini

### Interactions sociales
- Like (posts et commentaires)
- Commentaire (création, suppression, like)
- Signalement (posts, utilisateurs)

### Intégration musicale
- Apple Music (sélection de musique, prévisualisation 30s, bibliothèque, playlists)
- Statistiques d'écoute (top artistes, temps d'écoute, top musique, historique  — calculé client-side via MusicKit)

### Messagerie
- Liste de conversations
- Messages textuels (envoi)
- Messages musicaux (partage de titres Apple Music)
- Messages photo (envoi d'images vers Azure)
- Discussions de groupe (création, quitter)
- Temps réel via Mercure SSE
- Partage de Post / Playlist

### Recherche
- Recherche d'utilisateurs (par nom d'utilisateur)
- Recherche de posts
- Historique des recherches (local)

### Notifications
- Notifications push pour les nouveaux messages (FCM → APNs)
- Paramétrage des notifications (par type)

---

## Work Breakdown Structure (WBS)

Le WBS décompose le projet en lots de travail livrables, organisés par couche technique.

### Infrastructure & DevOps

- Environnement de développement local (Docker Compose : FrankenPHP, PostgreSQL, Redis, Messenger Worker)
- Infrastructure cloud Azure (Terraform — couches persistante et éphémère)
- Cluster Kubernetes (staging 2 VMs + production 3 VMs)
- Pipelines CI/CD (GitHub Actions : lint, tests, build, deploy, approbation manuelle production)
- Health checks automatisés (toutes les 4h, statut publié via GitHub Gist)

### Backend (API Symfony)

**Authentification**
- Demande OTP (génération, hash bcrypt, envoi email)
- Vérification OTP + génération JWT RS256 (TTL 24h)
- Gestion expiry et nettoyage des entrées `VerificationUser`

**Gestion des utilisateurs**
- CRUD profil (photo, bio, username, téléphone)
- Paramètres de confidentialité par champ
- Paramètres de notifications par type
- Enregistrement token FCM
- Suppression de compte

**Abonnements**
- Suivre / se désabonner
- Listes followers / following paginées avec respect des paramètres de confidentialité

**Posts & Feed**
- Création de post (upload double image vers Azure, résolution Track)
- Modification et suppression de post
- Compteur de vues Redis (anti-doublon)
- Feed privé (chronologique inversé)
- Feed public (algorithme de scoring par pertinence)

**Interactions sociales**
- Like / unlike polymorphique (`Post`, `Comment`)
- Commentaires (création, suppression)
- Signalements (`Post`, `User`) — dashboard admin non implémenté

**Messagerie**
- Conversations 1:1 et de groupe
- Messages textuels, musicaux, photo
- Gestion des membres (admin : ajouter / retirer / renommer)
- Quitter une conversation, marquer comme lu
- Publication d'événements Mercure SSE
- Notifications push FCM (messages/follow/like/comment)

**Recherche**
- Endpoint multi-type : `users`, `posts`, `tracks`, `artists`

### Application iOS (SwiftUI)

**Authentification & Onboarding**
- Écran saisie email + OTP
- Écran création de profil (première connexion, `needsProfile=true`)
- Gestion JWT (Keychain, expiry, gestion 401)

**Profil & Paramètres**
- Affichage et édition du profil
- Paramètres de confidentialité et de notifications
- Déconnexion
- Affichage Playlist AppleMusic

**Intégration Apple Music (MusicKit)**
- Demande de permission au premier lancement
- Calcul des statistiques d'écoute client-side (par lots de 100, max 2000 titres)
- Sélecteur de titres (playlists, prévisualisation 30s)

**Feed & Posts**
- Feed privé et feed public (scroll infini)
- Création / suppression de post
- Affichage détail post

**Interactions sociales**
- Like / unlike (posts, commentaires)
- Commentaires (affichage, création, suppression)
- Signalement (post, utilisateur)
- Abonnements (suivre, se désabonner, listes)

**Messagerie**
- Liste des conversations
- Affichage et envoi de messages (texte, musique, photo, date d'envoi)
- Création et gestion de groupes
- Connexion SSE Mercure (pause/reprise arrière-plan)

**Recherche**
- Écran de recherche multi-type
- Historique local des recherches récentes

**Notifications push**
- Enregistrement token FCM
- Deep link vers la donnée concernée

### Site vitrine (Next.js)

- Pages de présentation de l'application
- Optimisation SEO (SSR / SSG)
- Animations et interactions (GSAP)
