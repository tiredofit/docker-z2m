ARG DISTRO=alpine
ARG DISTRO_VARIANT=3.21

FROM docker.io/tiredofit/nginx:${DISTRO}-${DISTRO_VARIANT}-6.5.18
LABEL maintainer="Dave Conroy (github.com/tiredofit)"

ARG Z2M_VERSION

ENV Z2M_VERSION=2.5.0 \
    Z2M_REPO_URL=https://github.com/koenkk/zigbee2mqtt \
    CONTAINER_PROCESS_RUNAWAY_PROTECTOR=FALSE \
    NGINX_SITE_ENABLED=z2m \
    NGINX_WEBROOT=/var/lib/nginx/wwwroot \
    NGINX_ENABLE_CREATE_SAMPLE_HTML=FALSE \
    NGINX_LOG_ACCESS_LOCATION=/logs/nginx \
    NGINX_LOG_ERROR_LOCATION=/logs/nginx \
    NGINX_WORKER_PROCESSES=1 \
    NODE_ENVIRONMENT=production \
    IMAGE_NAME="tiredofit/z2m" \
    IMAGE_REPO_URL="https://github.com/tiredofit/docker-z2m/"

RUN source assets/functions/00-container && \
    set -x && \
    addgroup -S -g 2323 z2m && \
    adduser -D -S -s /sbin/nologin \
            -h /dev/null \
            -G z2m \
            -g "z2m" \
            -u 2323 z2m \
            && \
    \
    package update && \
    package upgrade && \
    package install .z2m-build-deps \
                    g++ \
                    gcc \
                    git \
                    linux-headers \
                    make \
                    nodejs \
                    npm \
                    python3 \
                    && \
    \
    package install .z2m-run-deps \
                    eudev \
                    nodejs \
                    && \
    \
    ##
    clone_git_repo "${Z2M_REPO_URL}" "${Z2M_VERSION}" /usr/src/z2m && \
    npm install && \
    npm run build && \
    mkdir /app && \
    mv LICENSE /app/ && \
    mv dist /app/ && \
    mv index.js /app/ && \
    mv package*.* /app/ && \
    mkdir -p /assets/z2m/ && \
    mv data/*.yaml /assets/z2m/ && \
    \
    cd /app && \
    npm ci \
            --omit=dev \
            --no-audit \
            --no-optional \
            --no-update-notifier \
            && \
    \
    npm rebuild --build-from-source && \
    \
    package remove .z2m-build-deps \
                    && \
    package cleanup && \
    \
    rm -rf /usr/src/*

EXPOSE 2323

COPY install /

