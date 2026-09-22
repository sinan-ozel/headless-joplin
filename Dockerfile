FROM node:22-slim

# Single source of truth for the image version: the tag published to Docker Hub
# is the Joplin version installed here. CI reads this line.
ARG JOPLIN_VERSION=3.7.2

# OCI build-time arguments — populated by CI.
ARG VERSION
ARG BUILD_DATE
ARG GIT_REVISION
ARG TITLE
ARG DESCRIPTION
ARG AUTHORS
ARG LICENSES
ARG SOURCE_URL
ARG DOCS_URL
ARG IMAGE_URL

# socat: Joplin's Data API hard-codes listen(port, '127.0.0.1'), so a forwarder
# is needed to make it reachable from outside the container.
RUN apt-get update \
    && apt-get install -y --no-install-recommends socat ca-certificates tini \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g "joplin@${JOPLIN_VERSION}" && npm cache clean --force

ENV JOPLIN_VERSION=${JOPLIN_VERSION}

EXPOSE 41184

# https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.title="${TITLE}" \
      org.opencontainers.image.description="${DESCRIPTION}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.authors="${AUTHORS}" \
      org.opencontainers.image.licenses="${LICENSES}" \
      org.opencontainers.image.source="${SOURCE_URL}" \
      org.opencontainers.image.documentation="${DOCS_URL}" \
      org.opencontainers.image.url="${IMAGE_URL}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${GIT_REVISION}"

COPY --chmod=755 src/entrypoint.sh /usr/local/bin/entrypoint.sh

ENV JOPLIN_PROFILE_DIR=/data/profile
VOLUME /data/profile

ENTRYPOINT ["tini", "--", "/usr/local/bin/entrypoint.sh"]
