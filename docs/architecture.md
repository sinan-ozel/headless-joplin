# Architecture

## Why a forwarder

Joplin's Data API server hard-codes its listen address:

```js
this.server_.listen(this.port_, '127.0.0.1');
```

(`@joplin/lib/ClipperServer.js`, checked against Joplin 3.7.1). There is no
setting to change it, so the API is unreachable from outside the container.

The image therefore runs three things:

1. `joplin server start` on `JOPLIN_INTERNAL_PORT` (localhost only).
2. `socat` listening on `JOPLIN_API_PORT` on all interfaces and forwarding to
   the internal port.
3. A loop running `joplin sync` every `JOPLIN_WEBDAV_SYNC_INTERVAL_MINUTES`.

The server does not check the `Host` header, so proxied requests work.

## Sync

`joplin server start` does not sync by itself. Changes made through the API are
stored in the local profile and reach the WebDAV target on the next sync run;
changes made on other devices arrive the same way.

## Versioning

The Joplin version is pinned in one place: `ARG JOPLIN_VERSION` in the
`Dockerfile`. CI reads it and uses it as the image tag. Bumping it is how a new
stable image is published; builds from `main` that change the image without
bumping it are published as `<joplin-version>-dev<timestamp>`.
