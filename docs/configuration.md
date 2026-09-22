# Configuration

All configuration is through environment variables.

## WebDAV sync

| Variable | Default | Description |
|---|---|---|
| `JOPLIN_WEBDAV_SYNC_URL` | *(unset)* | WebDAV server to sync with. Accepts `https://host`, `http://host`, or a bare `host`. A bare host defaults to **https**; an explicit scheme is used as given. If unset, sync is disabled. |
| `JOPLIN_WEBDAV_SYNC_USERNAME` | `''` | WebDAV username. Empty is allowed (no authentication). |
| `JOPLIN_WEBDAV_SYNC_PASSWORD` | `''` | WebDAV password. Empty is allowed. Plaintext, so pass it from a Secret if you set one. |
| `JOPLIN_WEBDAV_SYNC_PATH` | `/` | Path on the WebDAV server that holds the notebook data. |
| `JOPLIN_WEBDAV_SYNC_INTERVAL_MINUTES` | `5` | Minutes between syncs. `0` disables the sync loop. |
| `JOPLIN_WEBDAV_SYNC_ON_START` | `true` | Run one sync before the API starts answering, so it doesn't serve an empty profile on first boot. |

!!! note "Private CAs"
    With an `https://` URL signed by a private CA (for example step-ca), Node
    does not trust it by default. Mount the CA certificate into the container
    and set `NODE_EXTRA_CA_CERTS` to its path.

## Data API

| Variable | Default | Description |
|---|---|---|
| `JOPLIN_API_TOKEN` | *(required)* | Token every Data API request must carry (`?token=…`). |
| `JOPLIN_API_PORT` | `41184` | Port the API is exposed on (all interfaces). |
| `JOPLIN_INTERNAL_PORT` | `41185` | Port Joplin itself listens on, localhost only. Only change it on a clash. |

### `JOPLIN_API_TOKEN`

The Data API has no other authentication: anyone holding the token can read,
change and delete every note. Normally Joplin generates a random token and
shows it in the desktop app's Web Clipper settings. A headless instance has no
UI to read it from, so it is set explicitly. That way clients know it in
advance and it survives restarts.

The container refuses to start without it, rather than running an open API.

## Storage and process

| Variable | Default | Description |
|---|---|---|
| `JOPLIN_PROFILE_DIR` | `/data/profile` | Joplin profile (SQLite database, resources, settings). Mount a volume here. It is a cache of the sync target, so it can be rebuilt by syncing. |
| `PUID` / `PGID` | `1000` | User and group Joplin runs as. The profile directory is chowned to them on start. |
| `TZ` | `UTC` | Time zone. |
| `JOPLIN_LOG_LEVEL` | `info` | Log verbosity. |

## End-to-end encryption

| Variable | Default | Description |
|---|---|---|
| `JOPLIN_E2EE_PASSWORD` | *(unset)* | Master password for end-to-end encryption. |

End-to-end encryption (E2EE) is a Joplin option that encrypts notes on the
client before they are sent to the sync target, so the WebDAV server only ever
stores ciphertext. It is off by default. You can check in the desktop or mobile
app under *Settings → Encryption*.

If E2EE is **enabled** on your sync target, the headless client must know the
master password to read the notes, otherwise the API will return encrypted
items it cannot decrypt. Set `JOPLIN_E2EE_PASSWORD` to it, from a Secret.

If E2EE is **not** enabled, leave this unset. Do not set it to enable E2EE from
the headless side; enable it from a regular client first.
