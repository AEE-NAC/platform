# --- ÉTAPE 1 : Builder (Compilation des dépendances) ---
FROM python:3.12-slim-bookworm AS builder

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    libldap2-dev \
    libsasl2-dev \
    libssl-dev \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY requirements.txt .
# On installe les dépendances dans un dossier temporaire /install
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# --- ÉTAPE 2 : Image Finale (Exécution) ---
FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    ODOO_RC=/etc/odoo/odoo.conf

# 1. Dépendances de runtime (librairies partagées uniquement)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    xz-utils \
    gettext-base \
    postgresql-client \
    libldap-2.5-0 \
    libsasl2-2 \
    libssl3 \
    libpq5 \
    # Polices et dépendances pour wkhtmltopdf
    fonts-noto-cjk \
    xfonts-75dpi \
    xfonts-base \
    libxrender1 \
    libfontconfig1 \
    libx11-6 \
    libjpeg62-turbo \
    # Node.js pour Odoo
    nodejs \
    npm \
    && npm install -g rtlcss \
    && rm -rf /var/lib/apt/lists/*

# 2. Installation wkhtmltopdf compatible Debian Bookworm
RUN set -x && \
    arch=$(dpkg --print-architecture) && \
    if [ "$arch" = "amd64" ]; then \
        url="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb"; \
    elif [ "$arch" = "arm64" ]; then \
        url="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_arm64.deb"; \
    fi && \
    curl -o wkhtmltox.deb -sSL "$url" && \
    apt-get update && \
    apt-get install -y --no-install-recommends ./wkhtmltox.deb && \
    rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# 3. Préparation utilisateur et dossiers
RUN useradd -m -d /var/lib/odoo -s /bin/bash odoo \
    && mkdir -p /etc/odoo /var/lib/odoo /mnt/extra-addons /app \
    && chown -R odoo:odoo /etc/odoo /var/lib/odoo /mnt/extra-addons /app

WORKDIR /app

# 4. Récupération des bibliothèques Python compilées à l'étape 1
COPY --from=builder /install /usr/local

# 5. Copie de ton Odoo Custom avec les bonnes permissions
COPY --chown=odoo:odoo . .

# Configuration finale
COPY --chown=odoo:odoo entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8069 8072
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
