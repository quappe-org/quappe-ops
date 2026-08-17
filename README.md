# quappe-ops

Operational setup for running the Quappe platform.

Today this is a **single-host Docker Compose** deployment (fits the current
SQLite architecture). Kubernetes/Prometheus/log-shipping remain a documented
*future* target — built when real load demands it, not before.

---

## Deploy on a DigitalOcean Droplet (current path)

Runs the published images `quappeorg/quappe-service` + `quappeorg/quappe-web`
via [`deploy/docker-compose.yml`](./deploy/docker-compose.yml). The web UI is
served on port 80; the service is internal-only; SQLite + the embedding model
live on a persistent Docker volume.

> **Prerequisite:** the Docker Hub images must be **public** (or add a
> `docker login` step), otherwise `docker compose pull` can't fetch them.

### Fastest path: paste the cloud-init script

On **Create → Droplets** (choose a **Fedora** image), paste the entire contents
of [`deploy/cloud-init.yml`](./deploy/cloud-init.yml) into the **Startup
Scripts** box. It runs once on first boot: installs Docker (via dnf + the Docker
CE repo), fetches the compose file, generates a `QUAPPE_SECRET`, opens the
firewall (firewalld), and starts everything. After boot, open
**http://YOUR_DROPLET_IP**. (Then skip to "Updating" below.)

> **Two gotchas learned the hard way:**
> 1. The script targets **Fedora** (dnf/firewalld). For an Ubuntu/Debian image
>    the package names differ (`apt`, `ufw`).
> 2. Keep the pasted content **pure ASCII**. Curly quotes or em-dashes make
>    cloud-init fail with `unacceptable character #x0080` and silently run
>    nothing. Verify on the box with `cloud-init status --long`.

### Or do it manually

### 1. Create the Droplet

- DigitalOcean → **Create → Droplets**.
- Image: **Ubuntu 24.04 LTS**. Choose the **Docker** Marketplace image if
  offered (Docker preinstalled), otherwise plain Ubuntu (we install Docker in
  step 3).
- Size: **2 vCPU / 4 GB** is the recommended sweet spot for smooth running
  (~$24/mo). The service lazily loads a multilingual embedding model (~300-600
  MB) on first semantic search, on top of two Node processes. A **1 vCPU / 2 GB**
  box (~$12/mo) boots and works but gets tight/sluggish once the model loads —
  fine for a quick look, not for smooth use. Running Ollama on the same box
  needs several GB more (or leave `/pulse` & `/my` on their graceful fallback).
  DO RAM/CPU resizing is reversible, so starting small and bumping later is safe.
- Add your **SSH key**. Create.

### 2. Point DNS (optional, later)

For now we use the raw IP over http. When you add a domain, create an `A`
record → the Droplet IP, then follow "Add HTTPS" below.

### 3. SSH in and install Docker (skip if you used the Docker image)

```bash
ssh root@YOUR_DROPLET_IP

apt-get update && apt-get install -y docker.io docker-compose-plugin
systemctl enable --now docker
```

### 4. Get the compose file

```bash
mkdir -p /opt/quappe && cd /opt/quappe
# fetch just the deploy folder from quappe-ops
curl -fsSL https://raw.githubusercontent.com/quappe-org/quappe-ops/main/deploy/docker-compose.yml -o docker-compose.yml
curl -fsSL https://raw.githubusercontent.com/quappe-org/quappe-ops/main/deploy/.env.example -o .env.example
cp .env.example .env
```

### 5. Set the secret

```bash
# generate a strong JWT secret and put it in .env
echo "QUAPPE_SECRET=$(openssl rand -hex 32)" >> .env
# (edit .env to remove the empty QUAPPE_SECRET= line from the example if present)
nano .env
```

### 6. Pull and start

```bash
docker compose pull
docker compose up -d
docker compose ps          # both should be "running"
docker compose logs -f web # watch startup
```

Open **http://YOUR_DROPLET_IP** — the UI should load and the service seeds
~200 demo theses on first request.

### 7. Firewall

```bash
ufw allow OpenSSH
ufw allow 80/tcp
ufw enable
```

### Updating to a new release

CI publishes `:latest` on every push to `main`. To roll forward:

```bash
cd /opt/quappe
./deploy.sh          # or: docker compose pull && docker compose up -d
```

Grab the helper once: `curl -fsSL https://raw.githubusercontent.com/quappe-org/quappe-ops/main/deploy/deploy.sh -o /opt/quappe/deploy.sh && chmod +x /opt/quappe/deploy.sh`.

Data survives (it's on the `quappe-data` volume). To back up:
`docker run --rm -v quappe-data:/data -v $PWD:/backup busybox tar czf /backup/quappe-db.tgz /data`.

### Add HTTPS (when you have a domain)

Put a reverse proxy with automatic TLS in front of `web`. The simplest is
**Caddy** — add a `caddy` service that proxies `:443` → `web:3000` and change
`web` to `expose` instead of publishing port 80. (A ready compose overlay can be
added here once a domain exists.)

---

## Future scope (Kubernetes, when load demands it)

- **Kubernetes** manifests / Helm for service + web (service as a Deployment
  with a PersistentVolume for SQLite + model cache; web stateless with
  `PRIVATE_SERVICE_URL` at the in-cluster DNS; TLS ingress in front of web).
- **Prometheus** + Alertmanager; **log shipping** to OpenSearch.
- A DB connection bouncer — only once the service moves off single-instance
  SQLite to Postgres with replicas. Not before.

Guiding principle: build an operational capability when a real pain appears —
not in anticipation.

## Platform

Part of the Quappe platform: **quappe-service** (API/DB/logic) ·
**quappe-web** (UI) · **quappe-ops** (this) · **quappe-insight** (analytics) ·
**quappe-docs** (the idea).

## License

PolyForm Noncommercial 1.0.0 — see [`LICENSE`](./LICENSE).
