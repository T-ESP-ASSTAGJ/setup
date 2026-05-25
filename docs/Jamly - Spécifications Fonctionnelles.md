# Jamly — Spécifications Fonctionnelles

## Gestion des utilisateurs

### Inscription

**Acteur** : Utilisateur de l'application.

**Déclencheur** : L'utilisateur souhaite créer un compte.

**Scénario principal** :
1. L'utilisateur saisit son adresse email.
2. Il reçoit par email un code de vérification à 6 chiffres (valable 10 minutes).
3. Il saisit le code dans l'application.
4. S'il n'a pas encore de profil, il est redirigé vers l'écran de configuration du profil (username obligatoire, bio et photo optionnels).
5. Une fois le profil configuré, il accède à l'application.

**Règles métier** :
- L'email donné doit être valide.
- Le code OTP est un nombre à 6 chiffres, valable 10 minutes.
- Le username est obligatoire (minimum 3 caractères, unique).
- La bio et la photo de profil sont optionnelles.

---

### Connexion

**Acteur** : Utilisateur de l'application.

**Scénario principal** :
1. L'utilisateur saisit son adresse email.
2. Il reçoit un code OTP à 6 chiffres par email.
3. Il saisit le code.
4. Un token JWT (RS256, durée 24h) est généré et stocké dans le Keychain.

**Règles métier** :
- Authentification 100% sans mot de passe.
- Après 24h, le token expire et l'utilisateur doit se réauthentifier.

---

### Déconnexion

**Acteur** : Utilisateur connecté.

**Scénario** :
1. L'utilisateur appuie sur "Déconnexion" dans les paramètres de son profil.
2. Le token JWT est supprimé du Keychain.
3. L'utilisateur est redirigé vers l'écran de connexion.

---

### Modifier son profil

**Acteur** : Utilisateur connecté.

**Champs modifiables** :
- Photo de profil
- Bio (texte libre)
- Username
- Numéro de téléphone (optionnel)

**Scénario** :
1. L'utilisateur accède à son profil et appuie sur "Modifier".
2. Il modifie les champs souhaités.
3. Les modifications sont envoyées au backend.

---

### Paramètres du compte

**Acteur** : Utilisateur connecté.

**Confidentialité** (chaque champ : `public`, `friends` ou `privé`) :
- Visibilité des abonnés
- Visibilité des abonnements
- Visibilité des statistiques musicales
- Visibilité des playlists
- Visibilité des likes

**Notifications** (chaque type : activé / désactivé) :
- Nouveaux abonnés
- Likes
- Commentaires
- Messages

---

### Statistiques musicales

**Acteur** : Utilisateur connecté avec Apple Music autorisé.

**Données affichées** :
- Top 10 titres (par nombre d'écoutes)
- Top 10 artistes (agrégé par nombre d'écoutes)
- Top 10 albums
- Top 10 genres
- Temps d'écoute total estimé

**Fonctionnement** :
- Les données sont calculées côté client depuis la bibliothèque Apple Music (MusicKit).
- Traitement par lots de 100 titres (max 2000 titres analysés).
- Aucune donnée n'est envoyée au backend.

---

## Abonnements

**Suivre un utilisateur** :
1. L'utilisateur accède au profil d'un autre utilisateur.
2. Il appuie sur "Suivre".
3. Le bouton passe à "Ne plus suivre".

**Se désabonner** :
1. L'utilisateur appuie sur "Ne plus suivre".
2. La relation est supprimée.

**Listes** :
- Liste des abonnés (paginée), soumise à `followersVisibility`.
- Liste des abonnements (paginée), soumise à `followingVisibility`.

---

## Publication de contenu

### Création de post

**Acteur** : Utilisateur connecté.

**Scénario** :
1. L'utilisateur appuie sur le bouton de création (+).
2. Il sélectionne un titre depuis sa bibliothèque Apple Music (obligatoire).
3. Il choisi 2 photos de sa gallerie
4. Il ajoute une description (optionnelle, max 1000 caractères) et une localisation (optionnelle).
5. Les images sont compressées, encodées en base64, et envoyées au backend.

**Traitement backend** :
1. Validation des entrées.
2. Lookup du titre par `songId`, création si absent.
3. Upload de l'image frontale vers le stockage.
4. Upload de l'image arrière vers le stockage.
5. Création du post en base de données.

**Champs du post** :
- `track` : songId (Apple Music), titre, artiste — **obligatoire**
- `caption` : description — optionnel, max **1000 caractères**
- `frontImage` : base64
- `backImage` : base64
- `location` : texte — optionnel, max 255 caractères

---

### Suppression de post

**Acteur** : Propriétaire du post.

Suppression définitive du post et de toutes ses interactions (commentaires, likes) en cascade.

**Restriction** : propriétaire uniquement.

---

## Fil d'actualité

### Feed privé

**Acteur** : Utilisateur connecté.

- Posts des utilisateurs suivis uniquement.
- Ordre chronologique inversé (plus récents en premier).
- Paginé (20 posts par page).
- Feed vide si l'utilisateur ne suit personne.

---

### Feed public (découverte)

- **Utilisateurs non authentifiés** : ordre chronologique inversé.
- **Utilisateurs authentifiés** : algorithme de pertinence.

**Algorithme de scoring** (authentifiés) :

| Signal | Points |
|--------|--------|
| Titre du post dans les titres commentés par l'utilisateur | +15 |
| Titre du post dans les titres likés par l'utilisateur | +10 |
| Artiste dans les artistes commentés par l'utilisateur | +8 |
| Artiste dans les artistes likés par l'utilisateur | +5 |
| Auteur du post suivi par l'utilisateur | +4 |
| Post créé il y a moins de 7 jours | +3 |
| Post avec > 50 likes | +3 |
| Post avec > 10 likes | +2 |
| Post avec > 0 likes | +1 |

Tri final : score DESC, puis `createdAt` DESC.

---

## Interactions sociales

### Like

**Acteur** : Utilisateur connecté.

- Applicable aux posts et aux commentaires.
- Contrainte unique par utilisateur et par entité.
- Le compteur `likesCount` est mis à jour sur l'entité.

---

### Commentaire

**Acteur** : Utilisateur connecté.

- Les commentaires s'affichent par ordre décroissant de date.
- Champ `content` obligatoire à la création.
- Suppression réservée au propriétaire du commentaire.
- Les commentaires sont likables (même logique que le like de post).

---

### Signalement

**Raisons disponibles** : Spam, Harassment, InappropriateContent, Copyright, Other.

**Champs** :
- `entityId` : ID de l'entité signalée
- `entityClass` : `Post` ou `User`
- `reason` : enum
- `message` : texte explicatif (optionnel)

Contrainte : un seul signalement par utilisateur par entité.

---

## Intégration musicale — Apple Music

**Autorisation** : MusicKit demande la permission à l'utilisateur au premier lancement.

**Accès bibliothèque** :
- `MusicLibraryRequest<Song>` — récupération par lots de 100 titres (max 2000)
- Champs lus : `playCount`, `duration`, `artistName`, `albumTitle`, `genreNames`

**Sélecteur de titres** :
- Parcourir les playlists de la bibliothèque (`MusicPlaylistsView`)
- Voir les titres d'une playlist avec prévisualisation 30s (`PlaylistDetailView`)
- Sélectionner un titre pour un post ou un message musical

**Statistiques** (calculées client-side, non envoyées au backend) :
- Top 10 titres par `playCount`
- Top 10 artistes (agrégé)
- Top 10 albums (agrégé)
- Top 10 genres
- Temps d'écoute total estimé

---

## Messagerie

### Messages textuels

**Acteur** : Utilisateur connecté et membre de la conversation.

**Scénario** :
1. L'utilisateur saisit un texte dans la zone de saisie.
2. Il envoie via le bouton d'envoi.
3. Le message apparaît instantanément (Mercure SSE).
4. L'horodatage et le nom de l'expéditeur sont affichés.

**Options** :
- Modifier un message (texte uniquement)
- Supprimer un message

---

### Messages musicaux

**Acteur** : Utilisateur connecté.

**Scénario** :
1. L'utilisateur appuie sur l'icône musicale dans la zone de saisie.
2. Le sélecteur Apple Music s'ouvre (bibliothèque, playlists).
3. Il sélectionne un titre (avec prévisualisation 30s disponible).
4. Le message est envoyé avec le `Track` associé.

**Affichage du message reçu** :
- Pochette de l'album
- Titre et artiste
- Lien vers Apple Music

**Règles métier** :
- La plateforme source est Apple Music uniquement.
- Le `Track` (songId Apple Music, titre, artiste) est requis.

---

### Messages photo

**Scénario** :
1. L'utilisateur appuie sur l'icône photo dans la zone de saisie.
2. Il sélectionne une photo depuis sa galerie.
3. La photo est uploadée vers le stockage.
4. L'URL est stockée et le message est envoyé.

**Affichage** :
- Miniature cliquable dans la conversation.
- Affichage plein écran au tap.

---

### Liste des conversations

Chaque conversation affiche :
- Nom du contact (1:1) ou nom du groupe
- Aperçu du dernier message
- Horodatage
- Badge de messages non lus (`unreadCount`, calculé à partir de `lastReadAt`)

---

### Discussions de groupe

**Création** :
1. L'utilisateur accède à l'onglet Messages.
2. Il sélectionne "Nouvelle conversation de groupe".
3. Il choisit les participants (multi-sélection).
4. Il saisit un nom de groupe.
5. La conversation est créée avec `participants` et `groupName`.

Le créateur reçoit le rôle `admin`, les autres membres reçoivent le rôle `member`.

**Pour tous les membres** :
- Quitter le groupe
- Marquer comme lu

---

### Temps réel — Mercure SSE

L'app iOS maintient une connexion SSE persistante au hub Mercure, abonnée au topic `/conversations/{conversationId}`.

**Format de l'événement** :
```json
{
  "type": "message",
  "entity": {
    "id": 42,
    "content": "...",
    "type": "text|image|music",
    "author": { "id": 1, "username": "..." },
    "conversation": { "id": 7 },
    "track": null,
    "createdAt": "..."
  }
}
```

Reconnexion automatique, pause en arrière-plan, reprise au premier plan.

---

## Recherche

Types supportés :
- `users` (défaut) — recherche par nom d'utilisateur (partielle, insensible à la casse)

Tous les résultats sont paginés.

L'app iOS stocke localement l'historique des recherches récentes.

---

## Notifications

### Notifications push

**Fournisseur** : Firebase Cloud Messaging (FCM) → Apple Push Notification Service (APNs)

**Enregistrement** : transmission du token FCM de l'appareil au backend.

**Exmples de notification** :

| Événement | Titre | Corps |
|-----------|-------|-------|
| Nouveau message (1:1) | Nom de l'expéditeur | "{expéditeur} vous a envoyé un message" |
| Nouveau message (groupe) | Nom du groupe | "{expéditeur} vous a envoyé un message" |

**Payload APNs** : sound=default, badge=1, mutable-content=1, `{ conversationId, profilePicture }`.

**Deep link** : tap sur la notification → ouverture directe du contenu.

---

### Paramètres de notifications

Toggles configurables :
- `notifyNewFollower` (boolean)
- `notifyLike` (boolean)
- `notifyComment` (boolean)
- `notifyMessage` (boolean)
