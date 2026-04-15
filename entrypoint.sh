#!/bin/bash
set -e

# Vérifie que les variables obligatoires sont présentes
required_vars=("DB_HOST" "DB_PORT" "DB_USER" "DB_PASSWORD" "DB_NAME")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "ERREUR: La variable d'environnement $var est manquante."
        exit 1
    fi
done

# Génère odoo.conf à partir du template en substituant les variables
envsubst < /app/odoo.conf.template > /etc/odoo/odoo.conf

echo "odoo.conf généré avec succès :"
echo "  DB_HOST     = $DB_HOST"
echo "  DB_PORT     = $DB_PORT"
echo "  DB_USER     = $DB_USER"
echo "  DB_NAME     = $DB_NAME"
echo "  WORKERS     = ${WORKERS:-2}"
echo "  LOG_LEVEL   = ${LOG_LEVEL:-info}"
# DB_PASSWORD volontairement non affiché

exec python /app/odoo-bin -c /etc/odoo/odoo.conf "$@"