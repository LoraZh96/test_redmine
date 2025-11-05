#!/usr/bin/env bash
set -euo pipefail

export RAILS_ENV=${RAILS_ENV:-production}
export REDMINE_LANG={REDMINE_LANG:-en}

# usage: file_env VAR [DEFAULT]
# support *_FILE secrets used with Docker swarm secrets
file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"

  if [[ -n "${!var:-}" && -n "${!fileVar:-}" ]]; then
    echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
    exit 1
  fi

  local val="$def"
  if [[ -n "${!var:-}" ]]; then
    val="${!var}"
  elif [[ -n "${!fileVar:-}" ]]; then
    val="$(< "${!fileVar}")"
  fi

  export "$var"="$val"
  unset "$fileVar"
}

ensure_database_config() {
  local config_path="config/database.yml"

  if [[ -f "$config_path" ]]; then
    return
  fi

  file_env "REDMINE_DB_POSTGRES"
  file_env "REDMINE_DB_PORT" "5432"
  file_env "REDMINE_DB_USERNAME"
  file_env "REDMINE_DB_PASSWORD"
  file_env "REDMINE_DB_DATABASE"
  file_env "REDMINE_DB_ENCODING" "utf8"
  file_env "REDMINE_DB_SSLMODE" "require"

  : "${REDMINE_DB_POSTGRES:?REDMINE_DB_POSTGRES or REDMINE_DB_POSTGRES_FILE must be set}"
  : "${REDMINE_DB_USERNAME:?REDMINE_DB_USERNAME or REDMINE_DB_USERNAME_FILE must be set}"
  : "${REDMINE_DB_PASSWORD:?REDMINE_DB_PASSWORD or REDMINE_DB_PASSWORD_FILE must be set}"
  : "${REDMINE_DB_DATABASE:?REDMINE_DB_DATABASE or REDMINE_DB_DATABASE_FILE must be set}"

  cat <<EOF > "$config_path"
production:
  adapter: postgresql
  host: ${REDMINE_DB_POSTGRES}
  port: ${REDMINE_DB_PORT}
  database: ${REDMINE_DB_DATABASE}
  username: ${REDMINE_DB_USERNAME}
  password: ${REDMINE_DB_PASSWORD}
  encoding: ${REDMINE_DB_ENCODING}
  sslmode: ${REDMINE_DB_SSLMODE}
EOF
}

wait_for_secret_key() {
  local secret_file="${REDMINE_SECRET_KEY_BASE_FILE:-/run/secrets/REDMINE_SECRET_KEY_BASE}"
  echo "Waiting for SECRET_KEY_BASE file..."
  local timeout=30
  while [ ! -f "$secret_file" ] && [ $timeout -gt 0 ]; do
    sleep 1
    timeout=$((timeout - 1))
  done
  if [ -f "$secret_file" ]; then
    echo "SECRET_KEY_BASE file found: $secret_file"
  else
    echo "SECRET_KEY_BASE file not found after waiting - generating temporary key"
  fi
}

ensure_secret_key() {
  # 1) Si un fichier secret est défini (cas des Docker Swarm secrets)
  if [[ -n "${REDMINE_SECRET_KEY_BASE_FILE:-}" && -f "${REDMINE_SECRET_KEY_BASE_FILE}" ]]; then
    SECRET_KEY_BASE="$(tr -d '\r\n' < "${REDMINE_SECRET_KEY_BASE_FILE}")"
    export SECRET_KEY_BASE
    echo "Loaded SECRET_KEY_BASE from ${REDMINE_SECRET_KEY_BASE_FILE}"
  # 2) Sinon, si la variable d’environnement existe déjà
  elif [[ -n "${REDMINE_SECRET_KEY_BASE:-}" ]]; then
    # On nettoie aussi la valeur au cas où il y aurait des caractères invisibles
    SECRET_KEY_BASE="$(printf '%s' "${REDMINE_SECRET_KEY_BASE}" | tr -d '\r\n')"
    export SECRET_KEY_BASE
    echo "Using SECRET_KEY_BASE from environment variable"
  fi

  # 3) fallback: Si aucune clé n’a été trouvée, on en génère une temporairement
  if [[ -z "${SECRET_KEY_BASE:-}" ]]; then
    echo "SECRET_KEY_BASE not found, generating a temporary one…"  
    if command -v openssl >/dev/null 2>&1; then
      SECRET_KEY_BASE="$(openssl rand -hex 64)"
    else
       # Si openssl n’est pas disponible, on utilise Ruby
      SECRET_KEY_BASE="$(ruby -e 'require "securerandom"; print SecureRandom.hex(64)')"
    fi
    export SECRET_KEY_BASE
  fi

  # On n’affiche pas la clé pour des raisons de sécurité, seulement sa longueur
  echo "SECRET_KEY_BASE ready (length: ${#SECRET_KEY_BASE})"       
}

# Copie automatique des migrations Redmine si nécessaire
ensure_migration_path() {
  if [ -d /usr/src/redmine/migrate ] && [ ! -d /usr/src/redmine/db/migrate ]; then
    echo "Copie des migrations Redmine vers db/migrate..."
    mkdir -p /usr/src/redmine/db
    cp -r /usr/src/redmine/migrate /usr/src/redmine/db/migrate     
  fi
}

maybe_reset_and_migrate_database() {
  echo "Vérification de l’état de la base de données Redmine..."   
  export SECRET_KEY_BASE=${SECRET_KEY_BASE:-$(cat /run/secrets/REDMINE_SECRET_KEY_BASE 2>/dev/null || true)}

  current_node=$(hostname)
  leader_node=$(getent hosts tasks.redmine | awk '{print $2}' | sort | head -n1 || true)

  if [ "$current_node" != "$leader_node" ] && [ -n "$leader_node" ]; then
    echo "Instance $current_node : migrations non exécutées (gérées par $leader_node)."
    return 0
  fi

  local tables_count
  tables_count=$(RAILS_ENV=production bundle exec rails runner "puts ActiveRecord::Base.connection.tables.reject{|t| ['schema_migrations','ar_internal_metadata'].include?(t)}.count" 2>/dev/null || echo 0)

  if [ "$tables_count" = "0" ]; then
    echo "Base vide détectée — initialisation..."
    RAILS_ENV=production bundle exec rake db:drop DISABLE_DATABASE_ENVIRONMENT_CHECK=1 || true
    RAILS_ENV=production bundle exec rake db:create

    RAILS_ENV=production bundle exec rake db:migrate || echo "Migration déjà en cours ailleurs..."
    sleep 3

    post_migrate_count=$(RAILS_ENV=production bundle exec rails runner "puts ActiveRecord::Base.connection.tables.reject{|t| ['schema_migrations','ar_internal_metadata'].include?(t)}.count" 2>/dev/null || echo 0)

    if [ "$post_migrate_count" -gt 0 ]; then
      echo "Chargement des données par défaut..."
      RAILS_ENV=production REDMINE_LANG=${REDMINE_LANG} bundle exec rake redmine:load_default_data || true
    else
      echo "Aucune table détectée après migration, données par défaut non chargées."
    fi

    echo "Base Redmine initialisée avec succès."
  else
    echo "Base déjà initialisée, démarrage normal."
  fi
}

# Determine if command intends to run Redmine
is_redmine_command=false
case "${1:-}" in
  rails|rake)
    is_redmine_command=true
    ;;
  bundle)
    if [[ "${2:-}" == "exec" ]]; then
      is_redmine_command=true
    fi
    ;;
esac

if $is_redmine_command; then
  cd /usr/src/redmine

  ensure_database_config
  ensure_secret_key

  bundle check || bundle install --jobs "$(nproc)" --retry 3       

  rm -f tmp/pids/server.pid

  maybe_reset_and_migrate_database
fi

exec "$@"
