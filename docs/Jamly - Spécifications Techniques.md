# Jamly — Spécifications Techniques

Ce document décrit les **choix structurants** du projet : architecture, conventions, modèles de données et flux critiques. Il ne liste pas exhaustivement les endpoints — la référence interactive est disponible via Swagger à `/api/docs`.

---

## Stack technique

| Couche | Technologie | Justification |
|--------|-------------|---------------|
| Serveur HTTP | FrankenPHP + Caddy | Worker mode (PHP reste en mémoire), hub Mercure intégré, TLS auto, HTTP/2+3 — un seul conteneur |
| Framework API | Symfony 7 + API Platform 4 | Génération automatique CRUD + OpenAPI, State Processors pour la logique métier, pas de contrôleur répétitif |
| Base de données | PostgreSQL 17 | Types avancés (JSONB, full-text), robustesse sur schémas relationnels complexes (graphe social) |
| Cache / File | Redis 7 | Triple usage : transport Messenger, cache applicatif, compteur de vues anti-doublon |
| Authentification | JWT RS256 (lexik/jwt-authentication-bundle) | Passwordless — aucun mot de passe stocké, surface d'attaque réduite |
| Médias | Azure Blob Storage + Flysystem | Abstraction du stockage, compatible multi-environnements |
| Temps réel | Mercure (SSE) | Intégré à FrankenPHP/Caddy, pas de service séparé |
| Notifications push | Firebase (FCM) + APNs | Via Symfony Messenger (async) |
| Client iOS | Swift 5.9+ / SwiftUI | iOS 17+, MVVM + Stores, async/await |

---

## Architecture backend

### Vue d'ensemble

```
FrankenPHP / Caddy (HTTP + Mercure hub + TLS)
         │
Symfony 7 / API Platform 4
    State Processors / Providers  ←  point d'entrée unique (pas de Controller)
         │
    Services
    ├── Repositories → Doctrine ORM → PostgreSQL
    └── Intégrations externes (Azure, Firebase, Mercure…)
         │
    Symfony Messenger (bus async)
         │
    Redis  ←  transport + cache + compteur de vues
         │
    Workers (handlers async)
    ├── Notifications push (like, follow, commentaire, message)
    ├── Emails
    └── Persistance vues Redis → PostgreSQL
```

### Traitement asynchrone (Symfony Messenger)

Les opérations non-bloquantes sont dépilées du cycle requête/réponse via Redis :

| Message | Handler | Déclencheur |
|---------|---------|-------------|
| `CommentCreatedMessage` | Notification push auteur du post | Nouveau commentaire |
| `LikeCreatedMessage` | Notification push | Nouveau like |
| `FollowCreatedMessage` | Notification push | Nouveau follow |
| `MessageCreatedMessage` | Notification push + event Mercure | Nouveau message |
| `PersistPostViewsMessage` | Flush compteur Redis → base | Scroll du feed |

### Compteur de vues (Redis, anti-doublon)

Les vues sont incrémentées dans Redis (`post:views:{id}`) sans écriture en base à chaque appel. Un debounce (`post:view:debounce:{postId}:{userId}` avec TTL) empêche de compter plusieurs vues du même utilisateur sur une courte fenêtre. `PostViewsPersistenceService` flush périodiquement en base.

---

## Architecture iOS

### Couches (MVVM + Stores, sans framework externe)

```
View (SwiftUI)
  │  observe @Published
ViewModel (ObservableObject, @MainActor)
  │  appelle
Store (état global, @EnvironmentObject, @MainActor)
  │  appelle
Action (enum namespace, fonctions static par domaine)
  │  appelle
APIClient (singleton HTTP, JWT auto-injecté)
  │
Backend Jamly
```

**Règle stricte** : aucun appel réseau dans les vues. Tout passe par un ViewModel ou un Store.

### Stores globaux (`@EnvironmentObject`)

| Store | Responsabilité |
|-------|----------------|
| `UserStore` | Utilisateur connecté, feeds, token, pagination |
| `AuthManager` | État de connexion, flag `needsProfile` |
| `MusicManager` | Autorisation Apple Music, stats bibliothèque |
| `NotificationManager` | Token FCM, permissions push |

### Concurrence et `@MainActor`

| Type | Annotation | Raison |
|------|-----------|--------|
| Store / ViewModel | `@MainActor` sur la classe | Les `@Published` ne peuvent être mutés qu'en main thread |
| `APIClient` | aucune | L'appel réseau s'exécute sur un thread de pool ; l'appelant garantit le retour main |
| Délégué URLSession (`MercureService`) | `nonisolated` sur les callbacks | Callbacks depuis un thread arbitraire → bascule via `Task { @MainActor in … }` |
| Modèles `Codable` | aucune | Structs thread-safe par construction |

---

## Authentification

### Flux OTP (sans mot de passe)

```
1. POST /api/auth/request  →  code OTP 6 chiffres envoyé par email (valable 10 min)
2. POST /api/auth/verify   →  code vérifié → JWT RS256 retourné (TTL 24h)
3. Toutes les requêtes     →  Authorization: Bearer <token>
```

**Côté backend** : le code est hashé en bcrypt et stocké dans `VerificationUser`. L'entrée est supprimée après vérification réussie. Si l'utilisateur n'existe pas, il est créé avec `needsProfile=true`.

**Côté iOS** : après `verify`, `AuthManager.login(token:)` délègue à `UserStore.setToken()` qui persiste le JWT dans le Keychain via `SecureStore`. `RootView` observe `isAuthenticated` et bascule automatiquement.

**Auto-restauration au démarrage** : `UserStore.init` lit le token depuis le Keychain. S'il existe, `initialize()` charge le profil sans redemander de connexion.

**Déconnexion automatique sur 401** : `APIClient` supprime le token, poste `.didReceiveUnauthorized`, et lève `APIError.unauthorized`. `UserStore` et `AuthManager` écoutent et appellent `logout()`.

---

## Conventions API

### Globals

| Propriété | Valeur |
|-----------|--------|
| Base URL dev | `http://<ip-locale>:80/api` |
| Base URL prod | `https://api.jamly.app/api` |
| Format | JSON (`application/json`) |
| Dates | ISO 8601 — `2024-03-15T14:32:00+00:00` |
| Collections | Tableau JSON brut — pas de JSON-LD, pas d'enveloppe Hydra |
| PATCH | `Content-Type: application/merge-patch+json` (exigence API Platform) |

### Pagination

| Paramètre | Défaut | Description |
|-----------|--------|-------------|
| `page` | `1` | Numéro de page (base 1) |
| `itemsPerPage` | `20` | Éléments par page |

Une réponse vide ou partielle (< 20) signifie la fin du flux. Déduplication par `id` côté client.

### Format d'erreur — RFC 9457 Problem Details

```json
{
  "type": "https://tools.ietf.org/html/rfc2616#section-10",
  "title": "An error occurred",
  "detail": "email: This value is not a valid email address.",
  "status": 422
}
```

Les erreurs de validation (`422`) ajoutent un tableau `violations` :

```json
{
  "status": 422,
  "violations": [
    { "propertyPath": "email", "message": "This value is not a valid email address." }
  ]
}
```

### Codes HTTP

| Code | Signification |
|------|---------------|
| `200` | OK |
| `201` | Créé |
| `204` | Pas de contenu (ex. unlike, unfollow) |
| `400` | Requête malformée |
| `401` | Token manquant ou invalide |
| `403` | Authentifié mais non autorisé |
| `404` | Ressource introuvable |
| `422` | Échec de validation |

---

## Conventions iOS (couche réseau)

### `APIClient` — ce qu'il gère automatiquement

1. Construction de l'URL : `Config.baseURL + /api + path`
2. Sérialisation du body via `JSONEncoder`
3. Injection de `Authorization: Bearer <jwt>` si token présent
4. Forçage `application/merge-patch+json` sur les `PATCH`
5. Décodage de la réponse en `T` ou levée d'une `APIError` typée
6. Déconnexion automatique sur `401`

### Pipeline d'erreurs (deux étages)

| Cas backend | `APIError` (réseau) | `AppError` (UI) |
|-------------|---------------------|-----------------|
| 200-299 + body décodable | aucune | aucune |
| 401 | `.unauthorized` + logout auto | `.unauthorized` |
| Autres 4xx/5xx | `.serverError(code, data)` | `.serverError` |
| Timeout / pas de réseau | `.networkError(Error)` | `.networkError` |
| URL invalide | `.invalidURL` | `.unknown` |
| Décodage JSON KO | `.decodingFailed` | `.unknown` |

### Conventions de nommage

| Type | Convention | Exemple |
|------|-----------|---------|
| Body de requête | `XxxRequest` | `CreateCommentRequest` |
| Réponse ad hoc | `XxxResponse` | `AuthVerifyResponse` |
| Namespace d'actions | `XxxAction` / `XxxActions` | `FeedAction`, `UserActions` |
| ViewModel | `XxxViewModel` | `ChatsViewModel` |
| Chemins centralisés | `XxxEndpoints` | `UserEndpoints` |
| Modèle complet | Singulier | `Post`, `User` |
| Modèle allégé | `LightXxx` / `CommonXxx` | `LightMessage` |

---

## Temps réel (Mercure)

La messagerie utilise des **Server-Sent Events** via Mercure. L'envoi reste un POST HTTP classique ; seul la réception est temps réel.

```
Client iOS  →  POST /api/messages  →  Backend
                                         │ publie event Mercure
Client iOS  ←  SSE (MercureService)   ←──┘
```

`MercureService` maintient une connexion SSE persistante avec un buffer pour les fragments reçus à cheval entre deux callbacks. Le token SSE est récupéré via `GET /api/mercure/token` (JWT 50 min).

---

## Infrastructure (Azure + Kubernetes)

### Couches Terraform

| Couche | Contenu |
|--------|---------|
| Persistante (`infra/terraform/V2/persistent/`) | Resource Group, VNet, NSGs, VMs, comptes de stockage |
| Éphémère (`infra/terraform/V2/ephemeral/`) | Cluster Kubernetes rattaché au VNet persistant |

NSG du cluster : VXLAN Cilium (8472), Kubelet API (10250), K8s API Server (6443).

### Environnements

| Env | VMs | Taille |
|-----|-----|--------|
| Staging | 2 | Réduite |
| Production | 3 | Production |

### Docker Compose (local)

| Service | Configuration |
|---------|---------------|
| FrankenPHP + Caddy | API + hub Mercure, HTTP/2, HTTP/3, TLS auto |
| PostgreSQL 17 | Port 5432, volume persistant, healthcheck |
| Redis 7 | Port 6379, snapshots RDB, healthcheck |
| Symfony Messenger Worker | Consommateur async, limite 128 Mo RAM / 1h |

### GitHub Actions

- Plan / Apply / Destroy Terraform
- Approbation manuelle requise pour la production
- Health check toutes les 4 heures, statut publié via GitHub Gist
