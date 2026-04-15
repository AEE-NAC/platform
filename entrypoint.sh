#!/bin/bash
set -e

# 1. Vérification des variables
required_vars=("DB_HOST" "DB_PORT" "DB_USER" "DB_PASSWORD" "DB_NAME")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "ERREUR: La variable $var est manquante."
        exit 1
    fi
done

# 2. Setup config
export WORKERS="${WORKERS:-2}"
export MAX_CRON_THREADS="${MAX_CRON_THREADS:-1}"
export LOG_LEVEL="${LOG_LEVEL:-info}"
mkdir -p /etc/odoo
envsubst < /app/odoo.conf.template > /etc/odoo/odoo.conf

# 3. Logique d'auto-initialisation améliorée
echo "Vérification de l'état du RDS AWS ($DB_HOST)..."

# On compte les tables dans le schéma public
TABLE_COUNT=$(PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';" | xargs)

echo "Nombre de tables trouvées : $TABLE_COUNT"

# Odoo 'base' contient plus de 100 tables. Si on en a moins de 50, on initialise.
if [ "$TABLE_COUNT" -lt "50" ]; then
    echo "🚨 Base incomplète ou vide ($TABLE_COUNT tables). Initialisation forcée avec '-i base'..."
    set -- "-i" "base" "$@"
else
    echo "✅ Base de données prête ($TABLE_COUNT tables). Démarrage normal."
fi

echo "🚀 Lancement d'Odoo..."
exec python3 /app/odoo-bin -c /etc/odoo/odoo.conf "$@"