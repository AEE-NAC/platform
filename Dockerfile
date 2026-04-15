FROM python:3.12-slim-bookworm

# Dépendances système
RUN apt-get update && apt-get install -y --no-install-recommends \
    libldap2-dev \
    libsasl2-dev \
    libssl-dev \
    libpq-dev \
    gcc \
    build-essential \
    node-less \
    npm \
    curl \
    wget \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

# Création des dossiers nécessaires
RUN mkdir -p /etc/odoo /var/lib/odoo /var/log/odoo

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Copie du template et du script d'entrée
COPY odoo.conf.template /app/odoo.conf.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8069

ENTRYPOINT ["/entrypoint.sh"]