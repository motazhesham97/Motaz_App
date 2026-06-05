# motaz_app_server

Serverpod backend for the Motaz app.

The normal runtime path is Docker + Neon: one command starts the backend,
connects it to the Neon database, applies migrations, and exposes the API for
desktop, web, and Android devices. The Flutter app still keeps its own local
SQLite database for offline-first use.

## Run With Docker

From this directory:

```powershell
docker compose up -d --build
```

This starts:

- API server: `http://localhost:8080`
- Insights server: `http://localhost:8081`
- Web server: `http://localhost:8082`

PostgreSQL is not started by default. The production-style Docker backend uses
the Neon connection values from `.env` and the password from
`config/passwords.yaml`.

Follow logs:

```powershell
docker compose logs -f server
```

Stop the stack:

```powershell
docker compose down
```

Stop and delete the local database volume:

```powershell
docker compose down -v
```

## Android Phone Connection

The phone must call the laptop/server LAN IP, not `localhost`.

1. Find the laptop IP:

   ```powershell
   ipconfig
   ```

2. Set the public host before starting Docker:

   ```powershell
   $env:MOTAZ_PUBLIC_HOST="10.226.182.94"
   docker compose up -d --build
   ```

3. Keep `motaz_app_flutter/assets/config.json` aligned:

   ```json
   {
     "apiUrlAndroid": "http://10.226.182.94:8080",
     "runMode": "docker"
   }
   ```

If the Wi-Fi network changes, update the IP and rebuild/restart.

## Docker Secrets

Neon/production passwords live in:

```text
config/passwords.yaml
```

The file is ignored by Git and mounted into the container at runtime, so secrets
are not baked into the Docker image.

For production deployment, change:

- `config/passwords.yaml`
- Neon database variables in `.env` or in the hosting platform
- `MOTAZ_PUBLIC_HOST`
- `MOTAZ_PUBLIC_SCHEME`
- port variables if the deployment platform requires different ports

See `.env.docker.example` for the available variables.

## Deploy on Railway

Railway runs the backend as one Docker service. It does not use
`docker-compose.yaml`, and it provides the public HTTP port through the `PORT`
environment variable. The repository includes `../railway.toml` for Railway's
config-as-code deployment.

In Railway:

1. Create a new service from the GitHub repository.
2. Set **Root Directory** to:

   ```text
   /motaz_app
   ```

3. Let Railway use `railway.toml`. It points to:

   ```text
   motaz_app_server/Dockerfile
   ```

4. Add a Railway public domain for the backend service.
5. Add the variables from `.env.railway.example`.

Use the direct Neon host, not the `-pooler` host, because the container starts
with `--apply-migrations`. Keep the current production auth secrets if existing
users should keep working.

After the deploy is healthy, update the Flutter app server URL to:

```text
https://<your-railway-domain>
```

The mobile app remains offline-first. Railway hosts the online sync server,
while the phone still keeps its local SQLite database.

## Optional Local PostgreSQL

Use the local PostgreSQL container only for isolated tests or a deliberate local
server database:

```powershell
docker compose --profile local-db up -d postgres
```

Do not use the local PostgreSQL profile with your normal app data unless you
intend to create a separate empty server database. Switching between Neon and a
local server database changes the server fingerprint and blocks sync until the
local app database is rebound or reset.

## Manual Development Fallback

Manual Dart execution still works when you need it:

```powershell
dart bin/main.dart --mode=development --apply-migrations
```
