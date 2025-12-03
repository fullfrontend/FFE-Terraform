# WordPress – Thème privé & plugins auto

Objectif : déployer un thème privé (repo Git séparé) et des plugins auto‑maintenus, avec pipeline CircleCI (push = déploiement), sans monorepo.

## Stratégie recommandée : images immuables (rollback rapide)
1) **Build d’image custom dans CircleCI**  
   - Base : `wordpress:6.5-php8.2-apache` (ou tag équivalent).  
   - Cloner le thème privé (deploy key read‑only).  
   - Copier le thème dans `/usr/src/wordpress/wp-content/themes/<mon-theme>`.  
   - Installer/activer les plugins nécessaires via wp-cli (pinner les versions) ou les placer dans `wp-content/plugins`.  
   - Activer si besoin : `wp plugin auto-updates enable --all` et `wp config set WP_AUTO_UPDATE_CORE minor --raw`.  
   - Builder/pusher l’image `registry.example.com/wordpress:<tag>` (tag = SHA/semver).
2) **Déploiement**  
   - `terraform/helm` : paramètre `image`/`tag` pointant vers l’image buildée.  
   - Rollback = remettre l’ancien tag (pas de dépendance à git-sync).
3) **Stockage**  
   - Garder le PVC `wp-content` pour les uploads. Le contenu du thème/plugins est dans l’image et est copié dans le volume au premier démarrage (volume vide).  
   - Après rollback, redéploiement de l’ancienne image remet les fichiers du thème/plugins (uploads conservés sur le PVC).
4) **Sécurité**  
   - Les clés SSH (thème privé) ne vivent que dans le pipeline CI (pas dans le cluster).
5) **Automatisation (push = deploy)**  
   - Repo thème : push → CircleCI build/push image → étape de déploiement (helm/terraform ou `kubectl set image`) avec le nouveau tag.  
   - Option : job dédié pour remettre l’ancien tag en cas de rollback.

## (Option alternative) Runtime sync
Si tu préfères éviter le rebuild : sidecar git-sync + initContainer wp-cli (plugins, auto-update). Rollback moins immédiat (dépend du contenu du PVC).

## Notes dev/prod
- Dev (minikube): IngressClass `nginx`, tester via `minikube tunnel` ou NodePort.  
- Prod (DOKS): IngressClass `traefik`.

## Commande minikube utilisée (dev)
```
minikube delete && minikube start --driver=docker \
  && minikube addons enable ingress \
  && minikube addons enable ingress-dns \
  && minikube addons enable metrics-server \
  && minikube dashboard
```
