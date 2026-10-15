# OpenBao-Image mit eingebackener Server-Konfiguration.
# Version gezielt pinnen (Hadolint DL3007 / Checkov CKV_DOCKER_*), nicht :latest.
ARG OPENBAO_VERSION=2.4.0
FROM openbao/openbao:${OPENBAO_VERSION}

LABEL authors="developer" \
      org.opencontainers.image.title="openbao" \
      org.opencontainers.image.description="OpenBao server with baked-in config"

COPY --chown=openbao:openbao config/openbao.hcl /openbao/config/openbao.hcl

# Raft-Storage und Logs müssen für den Nicht-Root-User beschreibbar sein.
USER root
RUN mkdir -p /openbao/file /openbao/logs \
    && chown -R openbao:openbao /openbao/file /openbao/logs
USER openbao

VOLUME ["/openbao/file"]
EXPOSE 8200 8201

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q --spider "http://127.0.0.1:8200/v1/sys/health?standbyok=true&sealedcode=200&uninitcode=200" || exit 1

CMD ["server"]
