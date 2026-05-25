# Documentation Jamly — Index

| Fichier | Contenu |
|---------|---------|
| [Jamly - Plan de Qualité.md](Jamly%20-%20Plan%20de%20Qualité.md) | Organisation (OBS), méthode, normes, tests, workflow, Definition of Done |
| [Jamly - Périmètre Fonctionnel.md](Jamly%20-%20Périmètre%20Fonctionnel.md) | PBS, WBS par couche technique, fonctionnalités hors périmètre |
| [Jamly - Spécifications Fonctionnelles.md](Jamly%20-%20Spécifications%20Fonctionnelles.md) | Scénarios, règles métier et comportements attendus par fonctionnalité |
| [Jamly - Spécifications Techniques.md](Jamly%20-%20Spécifications%20Techniques.md) | Authentification, référence API complète, architecture iOS, infrastructure |
| [Jamly - Annexes.md](Jamly%20-%20Annexes.md) | Justification des choix techniques |

---

## Résumé du projet

**Jamly** est une application sociale musicale iOS natif (SwiftUI, iOS 17+) intégrant Apple Music. Les utilisateurs publient des posts liés à des titres musicaux, interagissent (likes, commentaires, abonnements) et s'envoient des messages avec partage musical en temps réel via Mercure SSE.

**Stack technique** :
- Backend : PHP Symfony 7.3 + API Platform 4.1, FrankenPHP + Caddy, PostgreSQL 17, Redis 7
- Mobile : SwiftUI (iOS 17+), MusicKit, Keychain Services
- Temps réel : Mercure SSE (hub intégré à FrankenPHP)
- Notifications : Firebase Cloud Messaging → APNs
- Stockage fichiers : Azure Blob Storage
- Infra : Azure, Kubernetes, Terraform, GitHub Actions
- Site vitrine : Next.js 16.1.1, React 19, TypeScript, Tailwind CSS 4, GSAP
