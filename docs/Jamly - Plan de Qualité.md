# Jamly — Plan de Qualité

## Organisation structurelle (OBS)

### Par poste
Les collaborateurs sont amenés à changer d'équipe selon les besoins, mais ont une appétence particulière pour un aspect de l'application.

- Développeur Frontend iOS : Gaël, Jonathan, Alexandre
- Développeurs Backend : Timothée, Sergio, Samir
- DevOps : Antoine, Mathieu
- Designer : Gaël

### Par responsabilité
- Chef de projet : Timothée, Antoine
- Chef d'équipe : Gaël, Timothée, Antoine
- Testeurs : Gaël, Timothée, Antoine

---

## Méthode de développement

### Outils de gestion
- Gestion & Suivi de projet : Github, Google Docs, Discord
- Suivi des tickets : Github

### Méthodologie
- 1 réunion par mois en présentiel pour voir l'avancement global
- Des réunions ponctuelles au besoin (après follow-up, avant un rendu)
- Compte-rendus après chaque réunion

---

## Normes et conventions de développement

### DevOps
- PostgreSQL : base de données robuste, migrations, sauvegardes
- Github Actions : exécution des jobs CI/CD, mise en ligne sur les différents environnements
- Azure : infrastructure cloud
- Kubernetes : orchestration, scalabilité, déploiements fiables
- Terraform : Infrastructure as Code, reproductibilité, traçabilité

### Backend
- Langage : PHP Symfony 7.3 + API Platform 4.1
- Serveur : FrankenPHP + Caddy (HTTP/2, HTTP/3, TLS, Mercure intégré)
- Asynchrone : Mercure (SSE) et Symfony Messenger + Redis
- Normes : PSR-1, PSR-2, PSR-4, PSR-12

### Mobile
- Application iOS : SwiftUI (iOS 17+, natif iOS uniquement)
- Architecture : MVVM + Stores, async/await
- Intégration musicale : MusicKit (Apple Music uniquement)
- Temps réel : Mercure SSE via URLSession
- Stockage sécurisé : Keychain Services

### Site vitrine
- Next.js 16.1.1, React 19, TypeScript, Tailwind CSS 4, GSAP

### Gestion de version
- Outil : Github
- Nommage des branches : `ticket` (`TEM-01`)
- Nommage des commits : `gitmoji ticket` (`:sparkles: TEM-01`) + description optionnelle
- Pull requests obligatoires (automatique avec `#STAGING` dans le commit)

### Commentaires
- Commentaire par feature si nécessaire, en francais
- Norme PHPDoc pour l'API, SwiftDoc pour le client iOS

---

## Plan de tests

### Types de tests
- **Tests Unitaires** : vérifient une fonction ou un composant isolé — outils : PHPUnit (PHP), Testing d'Apple (Swift)
- **Tests d'Intégration** : vérifient l'interaction entre plusieurs modules — PHPUnit (PHP), XCTest (Swift)
- **Tests Fonctionnels** : vérifient que le système répond aux attentes — PHPUnit (PHP), XCTest (Swift)

### Outils d'analyse
- SonarQube : détecte bugs, vulnérabilités et problèmes de qualité
- PHPStan : analyse statique PHP
- PHPCS : respect des standards de codage PHP
- Trivy : scanner de vulnérabilités pour les dépendances et infrastructures

---

## Processus de livraison — Workflow

1. Assignation d'un ticket par le chef d'équipe
2. Développement dans une branche personnalisée
3. Création d'une pull request
4. Revue de code par au moins un membre du projet
5. Pipeline de tests (lint, tests, build)
6. Pull dans la branche de préprod
7. Déploiement dans l'environnement de staging (Azure)
8. Validation en staging et documentation de la feature
9. Pull sur master et déploiement automatique
10. Vérification de la production et fermeture du ticket

---

## Definition of Done

La Definition of Done définit l'ensemble des critères permettant de considérer qu'une fonctionnalité est réellement terminée. Elle garantit que chaque incrément livré respecte un niveau de qualité constant et peut être intégré sans risque dans l'application.

**1. Code**
- Écrit, relu et conforme aux standards du projet (ESLint, PHPCS)
- Versionné et poussé sur la branche prévue
- Aucun log ou debug inutile
- Aucune régression sur les fonctionnalités existantes

**2. Tests**
- Tests unitaires couvrant les nouveaux comportements (100%)
- Tests d'intégration pour les endpoints/API critiques
- Tests passant en local et sur le pipeline CI

**3. Documentation**
- User Story à jour
- README mis à jour si nécessaire
- Documentation technique mise à jour

**4. Fonctionnel**
- Tous les critères d'acceptation validés
- L'UX/UI correspond aux maquettes Figma
- Comportement testé par un membre de l'équipe

**5. Performance & Sécurité**
- Aucune alerte critique de performance ou de sécurité
- Inputs côté API validés (DTOs, types, schémas)
- Erreurs gérées proprement
- Endpoints protégés exigeant une authentification valide

**6. Intégration / CI-CD**
- Branche passant tous les checks CI (lint, tests, build)
- Build API/iOS/site vitrine généré sans erreur
- Code mergé sur la branche de destination
- Environnement de staging mis à jour

**7. Revue & Validation**
- Code relu par un membre de l'équipe
- Fonctionnalité validée sur l'environnement de test
- Aucun bug bloquant ou majeur lié à la User Story
