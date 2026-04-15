FROM python:3.12-slim-bookworm

# Éviter les fichiers .pyc et activer le flush des logs
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Dépendances système + wkhtmltopdf
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    xz-utils \
    libldap2-dev \
    libsasl2-dev \
    libssl-dev \
    libpq-dev \
    gcc \
    build-essential \
    node-less \
    npm \
    gettext-base \
    postgresql-client \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_amd64.deb \
    && apt-get install -y --no-install-recommends ./wkhtmltox.deb \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Installation de rtlcss pour le support du RTL
RUN npm install -g rtlcss

# Création de l'utilisateur odoo et des dossiers
RUN useradd -m -d /var/lib/odoo -s /bin/bash odoo \
    && mkdir -p /etc/odoo /var/lib/odoo /var/log/odoo /mnt/extra-addons \
    && chown -R odoo:odoo /etc/odoo /var/lib/odoo /var/log/odoo /mnt/extra-addons

WORKDIR /app

# Installation des dépendances Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copie du code source
COPY . .

# Configuration de l'environnement
ENV ODOO_RC /etc/odoo/odoo.conf
COPY odoo.conf.template /etc/odoo/odoo.conf.template
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Définition des volumes pour la persistance des fichiers (filestore)
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Ports : 8069 (web), 8072 (longpolling pour le chat)
EXPOSE 8069 8072

USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]