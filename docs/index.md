# headless-joplin

A Docker image that runs the [Joplin](https://joplinapp.org) terminal app as a
headless server and exposes the **Data API** (the Web Clipper service) on the
network, so scripts and tools can read and write your notes over HTTP.

- Syncs with a WebDAV target (with or without credentials, `http` or `https`).
- Serves the Data API on port `41184`.
- Image tag = the Joplin version it contains, e.g. `headless-joplin:3.7.1`.

See [Configuration](configuration.md) for every environment variable, and
[Architecture](architecture.md) for why the image is built the way it is.
