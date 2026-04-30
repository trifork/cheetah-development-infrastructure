FROM postgres:18.3-bookworm

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates curl git make g++ pkg-config libssl-dev; \
    if curl -fsSL -o /tmp/pg-oidc-validator-pgdg18.deb \
      https://github.com/percona/pg_oidc_validator/releases/download/latest/pg-oidc-validator-pgdg18.deb && \
      apt-get install -y --no-install-recommends /tmp/pg-oidc-validator-pgdg18.deb; then \
      echo "Installed pg_oidc_validator from Percona release package"; \
    else \
      echo "Percona package install failed; building pg_oidc_validator from source"; \
      rm -f /tmp/pg-oidc-validator-pgdg18.deb; \
      git clone --depth 1 --recurse-submodules https://github.com/percona/pg_oidc_validator.git /tmp/pg_oidc_validator; \
      make -C /tmp/pg_oidc_validator USE_PGXS=1 install -j"$(nproc)"; \
      rm -rf /tmp/pg_oidc_validator; \
    fi; \
    rm -f /tmp/pg-oidc-validator-pgdg18.deb; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*
