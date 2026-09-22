import os

import httpx

API_URL = os.environ.get("JOPLIN_API_URL", "http://joplin:41184")


def test_server_is_alive():
    """The Data API answers /ping from outside the container."""
    response = httpx.get(f"{API_URL}/ping", timeout=10)
    assert response.status_code == 200
    assert response.text == "JoplinClipperServer"
