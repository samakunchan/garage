# 🗄️ Guide de Gestion des Buckets et Clés Garage S3

Ce guide récapitule les commandes essentielles pour administrer Garage S3 et interagir avec vos buckets en local et en production, y compris l'utilisation du client MinIO (`mc`).

---

## 💻 1. Installation du Client MinIO (`mc`)

Le client MinIO (`mc`) est un outil CLI puissant pour interagir avec n'importe quel stockage S3 (dont Garage).

### Sur macOS (Local)

* **Via Homebrew** (Recommandé) :

  ```bash
  brew install minio/stable/mc
  ```

* **Téléchargement direct (M1/M2/M3/M4 Apple Silicon)** :

  ```bash
  curl https://dl.min.io/client/mc/release/darwin-arm64/mc -o mc
  chmod +x mc
  sudo mv mc /usr/local/bin/
  ```

* **Téléchargement direct (Mac Intel)** :

  ```bash
  curl https://dl.min.io/client/mc/release/darwin-amd64/mc -o mc
  chmod +x mc
  sudo mv mc /usr/local/bin/
  ```

### Sur Linux VPS (Production)

```bash
curl https://dl.min.io/client/mc/release/linux-amd64/mc -o mc
chmod +x mc
sudo mv mc /usr/local/bin/
```

---

## 🔌 2. Configurer les connexions (Alias `mc`)

Pour que `mc` sache à quel serveur se connecter, configurez un alias avec vos clés d'accès :

### En Local (Dev)

```bash
mc alias set dev-garage http://localhost:3900 <ACCESS_KEY> <SECRET_KEY>
```

### En Production (VPS)

```bash
mc alias set prod-garage https://garage.samakunchan-technology.com <ACCESS_KEY> <SECRET_KEY>
```

---

## 🛠️ 3. Commandes S3 courantes avec `mc`

Une fois l'alias configuré (ex: `prod-garage` ou `dev-garage`), utilisez ces commandes :

* **Lister les buckets** :

  ```bash
  mc ls prod-garage
  ```

* **Lister le contenu d'un bucket** :

  ```bash
  mc ls prod-garage/papanguesoft
  ```

* **Créer un nouveau bucket** :

  ```bash
  mc mb prod-garage/nom-du-nouveau-bucket
  ```

* **Uploader un fichier local** :

  ```bash
  mc cp mon-image.png prod-garage/papanguesoft/
  ```

* **Télécharger un fichier du bucket** :

  ```bash
  mc cp prod-garage/papanguesoft/mon-image.png ./
  ```

* **Supprimer un fichier dans un bucket** :

  ```bash
  mc rm prod-garage/papanguesoft/mon-image.png
  ```

* **Afficher l'espace utilisé** :

  ```bash
  mc du prod-garage/papanguesoft
  ```

---

## ⚙️ 4. Administration Serveur (via CLI Garage)

Ces commandes s'exécutent **directement sur le serveur** (VPS ou machine locale) via Docker.
*(Ajoutez `sudo` devant `docker` sur le VPS si nécessaire).*

### Gestion des Clés (Credentials)

* **Créer une clé** (affiche l'Access Key `GK...` et la Secret Key) :

  ```bash
  docker exec -it garage /garage key create <nom_de_la_cle>
  ```

* **Lister les clés actives** :

  ```bash
  docker exec -it garage /garage key list
  ```

* **Voir les détails d'une clé** :

  ```bash
  docker exec -it garage /garage key info <key_id>
  ```

* **Supprimer une clé** :

  ```bash
  docker exec -it garage /garage key delete <key_id>
  ```

### Gestion des Buckets (Seaux)

* **Créer un bucket** :

  ```bash
  docker exec -it garage /garage bucket create <nom_du_bucket>
  ```

* **Lister les buckets** :

  ```bash
  docker exec -it garage /garage bucket list
  ```

* **Afficher les détails et permissions d'un bucket** :

  ```bash
  docker exec -it garage /garage bucket info <nom_du_bucket>
  ```

### Gestion des Permissions & Accès Public

* **Lier une clé API à un bucket (Accès Lecture/Écriture)** :

  ```bash
  # Remplacez <key_id> par la clé commençant par GK...
  docker exec -it garage /garage bucket allow <nom_du_bucket> --read --write --key <key_id>
  ```

* **Retirer les permissions d'une clé sur un bucket** :

  ```bash
  docker exec -it garage /garage bucket deny <nom_du_bucket> --read --write --key <key_id>
  ```

* **Activer l'accès public (lecture anonyme) pour les fichiers** :

  ```bash
  docker exec -it garage /garage bucket website --allow <nom_du_bucket>
  ```

* **Désactiver l'accès public d'un bucket** :

  ```bash
  docker exec -it garage /garage bucket website --deny <nom_du_bucket>
  ```
