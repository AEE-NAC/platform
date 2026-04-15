FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# 1. Installation des dépendances système de base
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    xz-utils \
    gettext-base \
    postgresql-client \
    libldap2-dev \
    libsasl2-dev \
    libssl-dev \
    libpq-dev \
    gcc \
    build-essential \
    # Polices nécessaires pour wkhtmltopdf
    fonts-noto-cjk \
    xfonts-75dpi \
    xfonts-base \
    && rm -rf /var/lib/apt/lists/*

# 2. Installation intelligente de wkhtmltopdf selon l'architecture
RUN set -x && \
    arch=$(dpkg --print-architecture) && \
    if [ "$arch" = "amd64" ]; then \
        url="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_amd64.deb"; \
    elif [ "$arch" = "arm64" ]; then \
        url="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.jammy_arm64.deb"; \
    fi && \
    curl -o wkhtmltox.deb -sSL "$url" && \
    apt-get update && \
    apt-get install -y --no-install-recommends ./wkhtmltox.deb && \
    rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# 3. Installation Node.js (moins lourd que de passer par apt node-less)
RUN apt-get update && apt-get install -y --no-install-recommends nodejs npm && \
    npm install -g rtlcss && \
    rm -rf /var/lib/apt/lists/*

# 4. Préparation Odoo
RUN useradd -m -d /var/lib/odoo -s /bin/bash odoo \
    && mkdir -p /etc/odoo /var/lib/odoo /mnt/extra-addons \
    && chown -R odoo:odoo /etc/odoo /var/lib/odoo /mnt/extra-addons

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Configuration
ENV ODOO_RC /etc/odoo/odoo.conf
# On s'assure que le script est exécutable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8069 8072
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]