FROM nginx:1.27-alpine

LABEL org.opencontainers.image.title="Songloft Community Web"
LABEL org.opencontainers.image.description="Docker-ready Songloft Community Flutter Web player"
LABEL org.opencontainers.image.source="https://github.com/NeoHeee/songloft-community"
LABEL org.opencontainers.image.licenses="Apache-2.0"

RUN rm -f /etc/nginx/conf.d/default.conf

COPY docker/web/default.conf.template /etc/nginx/templates/default.conf.template
COPY docker/web/05-songloft.envsh /docker-entrypoint.d/05-songloft.envsh
COPY build/web/ /usr/share/nginx/html/

RUN chmod +x /docker-entrypoint.d/05-songloft.envsh \
    && test -f /usr/share/nginx/html/index.html

ENV SONGLOFT_API_URL=http://host.docker.internal:58091

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -q -O - http://127.0.0.1/healthz | grep -q '^ok$' || exit 1
