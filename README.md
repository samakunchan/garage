# 🚗 GarageHQ - Object Storage

Garage est un service de stockage d'objets (S3 compatible) léger et distribué.

## 🚀 Démarrage Rapide

1. **Initialisation** (génération des fichiers `garage.toml` et `compose.yml`) :

   * **En développement (Local) :**

     ```bash
     ./setup.sh
     ```

     *Configure par défaut Garage pour utiliser les domaines locaux `.localhost`.*

   * **En production (VPS) :**

     ```bash
     ./setup.sh prod <votre_domaine>
     # Exemple :
     ./setup.sh prod garage.samakunchan-technology.com
     ```

     *Configure Garage pour utiliser votre domaine de production.*

2. **Lancer les conteneurs** :

   ```bash
   docker compose up -d
   ```

## ⚙️ Configuration du Cluster (Obligatoire au premier lancement)

Même pour un seul nœud, vous devez configurer le plan de répartition des données (appelé **layout**). Cette étape permet de définir le rôle de chaque nœud physique, sa zone géographique, et sa capacité de stockage autorisée.

1. **Assigner le rôle au nœud actuel** :
   Cette commande associe le nœud actuel à une zone physique (`dc1`) et lui attribue une limite de stockage (`10G`). Nous extrayons dynamiquement l'identifiant hexadécimal du nœud grâce à la commande `node id` combinée à un filtre `cut` pour retirer l'adresse réseau.

   ```bash
   docker exec -it garage /garage layout assign --zone dc1 --capacity 10G $(docker exec garage /garage node id | cut -d'@' -f1)
   ```

2. **Appliquer les changements** :
   Les modifications de configuration du layout sont d'abord préparées à l'état de brouillon. Pour les activer et lancer la répartition des partitions sur le cluster, vous devez appliquer le layout en spécifiant une version (commencez par `1` au premier lancement).

  ```bash
  docker exec -it garage /garage layout apply --version 1
  ```

  ```groovy
  2026-07-16T12:06:23.245762Z  INFO garage_net::netapp: Connected to [::]:3901, negotiating handshake...
  2026-07-16T12:06:23.292558Z  INFO garage_net::netapp: Connection established to 20e799e3355a19e6
  ==== COMPUTATION OF A NEW PARTITION ASSIGNATION ====

  Partitions are replicated 1 times on at least 1 distinct zones.

  Optimal partition size:                     37.3 MiB
  Usable capacity / total cluster capacity:   9.3 GiB / 9.3 GiB (100.0 %)
  Effective capacity (replication factor 1):  9.3 GiB
  
  dc1                     Tags  Partitions        Capacity  Usable capacity
  20e799e3355a19e6        []    256 (256 new)     9.3 GiB   9.3 GiB (100.0%)
  TOTAL                   256 (256 unique)  9.3 GiB   9.3 GiB (100.0%)  
  ```

## 📊 Commandes Utiles

### État du Cluster

Cette commande permet de vérifier la santé du cluster, d'identifier les nœuds actifs connectés, leur version, leur zone géographique, ainsi que l'espace disque disponible et utilisé.

```bash
docker exec -it garage /garage status
```

```groovy
/** Output */
2026-07-16T11:55:15.241574Z  INFO garage_net::netapp: Connected to [::]:3901, negotiating handshake...
2026-07-16T11:55:15.285430Z  INFO garage_net::netapp: Connection established to 767750111a2d4264
==== HEALTHY NODES ====
ID                Hostname      Address    Tags  Zone  Capacity  DataAvail         Version
767750111a2d4264  7b5aeb3dedd9  [::]:3901  []    dc1   9.3 GiB   12.9 GiB (41.0%)  v2.3.0
```

### Gestion des Clés API (Credentials)

Les clés API S3 sont composées d'un **Access Key ID** (identifiant public de la clé) et d'un **Secret Access Key** (mot de passe privé associé). Elles permettent à vos applications clientes (comme le SDK Node.js, `aws-cli` ou `rclone`) de s'authentifier de manière sécurisée pour lire et écrire des données.

* **Créer une clé** :
  Génère un nouveau couple d'identifiants d'accès.

  > [!IMPORTANT]
  > La clé secrète (*Secret Access Key*) ne sera affichée qu'une seule fois au moment de la création. Sauvegardez-la soigneusement, car elle sera masquée par la suite.

  ```bash
  docker exec -it garage /garage key create <nom_de_la_cle>
  ```

* **Lister les clés** :
  Affiche la liste de toutes les clés d'accès API configurées sur le cluster.

  ```bash
  docker exec -it garage /garage key list
  ```

* **Voir les détails d'une clé** :
  Affiche les informations associées à une clé spécifique (nom, permissions de création de bucket, et buckets associés). La clé secrète y est masquée pour des raisons de sécurité.

  ```bash
  docker exec -it garage /garage key info <key_id>
  ```

### Gestion des Buckets (Seaux)

Un bucket est un espace de stockage nommé (analogue à un dossier partagé ou une partition logique) dans lequel sont organisés vos fichiers (objets).

* **Créer un bucket** :
  Initialise un nouveau conteneur de fichiers vide.

  ```bash
  docker exec -it garage /garage bucket create <nom_du_bucket>
  ```

* **Lister les buckets** :
  Affiche tous les buckets d'objets existants sur le cluster Garage.

  ```bash
  docker exec -it garage /garage bucket list
  ```

### Gestion des Permissions (Liaison Clés-Buckets)

Par défaut, une clé API nouvellement créée n'a aucun droit d'accès sur aucun bucket. Vous devez explicitement lier vos clés à vos buckets pour leur accorder des privilèges de lecture (`--read`) et/ou d'écriture (`--write`).

* **Autoriser une clé sur un bucket** :
  Associe une clé API spécifique à un bucket avec les permissions souhaitées (par exemple, lecture/écriture).

  ```bash
  docker exec -it garage /garage bucket allow <nom_du_bucket> --read --write --key <nom_de_la_cle>
  ```

## 🌐 Hébergement Web Public (Accès Anonyme)

Par défaut, tous les buckets créés dans Garage sont privés et nécessitent des identifiants d'accès S3 signés pour pouvoir lire ou télécharger les fichiers. Pour servir des ressources publiques de manière anonyme et directe dans le navigateur (ex: images de projets, CV au format PDF), vous devez activer le mode **site web** sur le bucket et passer par le port web **3902**.

### 1. Activer l'accès public sur un bucket

Cette commande autorise Garage à servir les fichiers de ce bucket à des utilisateurs non authentifiés (anonymes) :

```bash
docker exec -it garage /garage bucket website --allow <nom_du_bucket>
```

### 2. Accéder aux fichiers publiquement (Virtual-Hosted)

Dans la configuration `garage.toml`, le domaine d'hébergement web est défini par `root_domain = ".web.garage.localhost"`. Pour charger un fichier sans authentification, vous devez utiliser la syntaxe de sous-domaine suivante :

`http://<nom_du_bucket>.web.garage.localhost:3902/<nom_du_fichier>`

*Exemple concret pour le bucket `papanguesoft`* :
`http://papanguesoft.web.garage.localhost:3902/1784225727335-F2100018.pdf`

> [!NOTE]
> Sur macOS et la plupart des systèmes récents, tous les sous-domaines se terminant par `.localhost` (comme `<nom_du_bucket>.web.garage.localhost`) sont automatiquement résolus par le système vers l'adresse locale `127.0.0.1`. Aucun fichier `/etc/hosts` n'est à modifier.

## 🌐 API & Ports exposés

* **API S3 principale (Requêtes authentifiées)** :
  * **Endpoint (Dev)** : `http://localhost:3900`
  * **Endpoint (Prod)** : `https://garage.samakunchan-technology.com` (via proxy HTTPS)
  * **Port** : `3900`
  * **Région** : `garage`

* **Serveur S3 Web (Lecture anonyme publique)** :
  * **Endpoint (Dev)** : `http://<nom_du_bucket>.web.garage.localhost:3902`
  * **Endpoint (Prod)** : `https://<nom_du_bucket>.web.garage.samakunchan-technology.com` (via proxy HTTPS)
  * **Port** : `3902`

* **API d'Administration Console** :
  * **Endpoint** : `http://localhost:3903`
  * **Port** : `3903`

## ⚙️ Configuration en Production

Pour faire tourner Garage en production avec un nom de domaine et du HTTPS :

### 1. Configuration DNS

Créez les enregistrements A suivants pointant vers l'adresse IP publique de votre VPS :

* `garage.samakunchan-technology.com` -> `IP_VPS`
* `*.garage.samakunchan-technology.com` -> `IP_VPS` (Wildcard requis pour résoudre les sous-domaines des buckets)

### 2. Configuration Reverse Proxy (Exemple avec Nginx & SSL Let's Encrypt)

```nginx
# 1. API S3 principal (écriture)
server {
    listen 443 ssl;
    server_name garage.samakunchan-technology.com;

    ssl_certificate /etc/letsencrypt/live/garage.samakunchan-technology.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/garage.samakunchan-technology.com/privkey.pem;

    client_max_body_size 100M;

    location / {
        proxy_pass http://localhost:3900;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# 2. Accès public S3 Web (lecture anonyme)
server {
    listen 443 ssl;
    server_name *.garage.samakunchan-technology.com;

    ssl_certificate /etc/letsencrypt/live/garage.samakunchan-technology.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/garage.samakunchan-technology.com/privkey.pem;

    client_max_body_size 100M;

    location / {
        proxy_pass http://localhost:3902;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---
*Note: Toutes les commandes utilisent `docker exec -it garage /garage ...` car le binaire Garage est localisé à la racine du conteneur et n'est pas dans le PATH global par défaut.*
