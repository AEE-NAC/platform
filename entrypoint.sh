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

# 3. LOGIQUE D'AUTO-INITIALISATION
echo "Vérification de l'état de la base de données..."

# On tente de compter les tables dans la base. 
# Si le compte est 0, c'est que la base est vide.
TABLE_COUNT=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';" | xargs)

if [ "$TABLE_COUNT" -eq "0" ]; then
    echo "Base vide détectée ($TABLE_COUNT tables). Initialisation forcée avec '-i base'..."
    # On ajoute -i base automatiquement pour ce premier lancement
    set -- "$@" "-i" "base"
else
    echo "Base déjà initialisée ($TABLE_COUNT tables trouvées). Démarrage normal."
fi

echo "Lancement d'Odoo..."
exec python3 /app/odoo-bin -c /etc/odoo/odoo.conf "$@"