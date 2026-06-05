#!/bin/sh
set -e

RUNMODE="${runmode:-production}"
CONFIG_FILE="/app/config/${RUNMODE}.yaml"
PASSWORDS_FILE="/app/config/passwords.yaml"

export SERVERPOD_API_BIND_PORT="${SERVERPOD_API_BIND_PORT:-${PORT:-8080}}"
export SERVERPOD_API_HOST="${SERVERPOD_API_HOST:-${RAILWAY_PUBLIC_DOMAIN:-localhost}}"
export SERVERPOD_API_PORT="${SERVERPOD_API_PORT:-443}"
export SERVERPOD_API_SCHEME="${SERVERPOD_API_SCHEME:-https}"
export SERVERPOD_INSIGHTS_HOST="${SERVERPOD_INSIGHTS_HOST:-${SERVERPOD_API_HOST}}"
export SERVERPOD_INSIGHTS_PORT="${SERVERPOD_INSIGHTS_PORT:-443}"
export SERVERPOD_INSIGHTS_SCHEME="${SERVERPOD_INSIGHTS_SCHEME:-${SERVERPOD_API_SCHEME}}"
export SERVERPOD_WEB_HOST="${SERVERPOD_WEB_HOST:-${SERVERPOD_API_HOST}}"
export SERVERPOD_WEB_PORT="${SERVERPOD_WEB_PORT:-443}"
export SERVERPOD_WEB_SCHEME="${SERVERPOD_WEB_SCHEME:-${SERVERPOD_API_SCHEME}}"
export SERVERPOD_DATABASE_PORT="${SERVERPOD_DATABASE_PORT:-5432}"
export SERVERPOD_DATABASE_REQUIRE_SSL="${SERVERPOD_DATABASE_REQUIRE_SSL:-true}"
export SERVERPOD_REDIS_HOST="${SERVERPOD_REDIS_HOST:-localhost}"
export SERVERPOD_REDIS_PORT="${SERVERPOD_REDIS_PORT:-6379}"

require_env() {
  name="$1"
  eval value="\${$name:-}"
  if [ -z "$value" ]; then
    echo "Missing required environment variable: $name" >&2
    exit 1
  fi
}

require_env SERVERPOD_DATABASE_HOST
require_env SERVERPOD_DATABASE_NAME
require_env SERVERPOD_DATABASE_USER

if [ ! -f "$PASSWORDS_FILE" ]; then
  require_env SERVERPOD_DATABASE_PASSWORD
  require_env SERVERPOD_SERVICE_SECRET
  require_env SERVERPOD_EMAIL_SECRET_HASH_PEPPER
  require_env SERVERPOD_JWT_HMAC_SHA512_PRIVATE_KEY
  require_env SERVERPOD_JWT_REFRESH_TOKEN_HASH_PEPPER

  umask 077
  cat > "$PASSWORDS_FILE" <<EOF
production:
  database: ${SERVERPOD_DATABASE_PASSWORD}
  serviceSecret: ${SERVERPOD_SERVICE_SECRET}
  emailSecretHashPepper: ${SERVERPOD_EMAIL_SECRET_HASH_PEPPER}
  jwtHmacSha512PrivateKey: ${SERVERPOD_JWT_HMAC_SHA512_PRIVATE_KEY}
  jwtRefreshTokenHashPepper: ${SERVERPOD_JWT_REFRESH_TOKEN_HASH_PEPPER}
EOF
fi

if command -v envsubst >/dev/null 2>&1 && [ -f "$CONFIG_FILE" ]; then
  TMP_CONFIG="/tmp/serverpod-${RUNMODE}.yaml"
  envsubst < "$CONFIG_FILE" > "$TMP_CONFIG"
  cp "$TMP_CONFIG" "$CONFIG_FILE"
fi

exec /app/server \
  --mode="$RUNMODE" \
  --server-id="${serverid:-default}" \
  --logging="${logging:-normal}" \
  --role="${role:-monolith}" \
  "$@"
