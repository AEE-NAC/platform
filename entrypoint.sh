#!/bin/bash
set -e

# 1. Vérification des variables obligatoires
required_vars=("DB_HOST" "DB_PORT" "DB_USER" "DB_PASSWORD" "DB_NAME")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "ERREUR: La variable $var est manquante."
        exit 1
    fi
done

# 2. Setup config et dossier
export WORKERS="${WORKERS:-2}"
export MAX_CRON_THREADS="${MAX_CRON_THREADS:-1}"
export LOG_LEVEL="${LOG_LEVEL:-info}"

mkdir -p /etc/odoo
envsubst < /app/odoo.conf.template > /etc/odoo/odoo.conf

# 3. Logique d'auto-initialisation via psql
echo "Vérification de l'état du RDS AWS ($DB_HOST)..."

# On compte les tables. Si c'est 0, la base est neuve.
# PGPASSWORD permet d'utiliser psql sans interactivité
TABLE_COUNT=$(PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';" | xargs)

if [ "$TABLE_COUNT" -eq "0" ]; then
    echo "🚨 Base vide détectée. Lancement de l'initialisation forcée (-i base)..."
    # On insère -i base au début des arguments
    set -- "-i" "base" "$@"
else
    echo "✅ Base de données déjà initialisée ($TABLE_COUNT tables). Démarrage normal."
fi

echo "🚀 Lancement d'Odoo..."
exec python3 /app/odoo-bin -c /etc/odoo/odoo.conf "$@"