FROM python:3.12-slim

WORKDIR /workspace

RUN pip install --no-cache-dir "ruff>=0.12.11"

# Ruff config, formerly in pyproject.toml. Lives outside /workspace: the
# compose file mounts the repo over /workspace at runtime, which would shadow
# anything written there at build time.
RUN cat <<'EOF' > /ruff.toml
[lint]
select = ["I", "F", "E", "W"]
ignore = ["E501"]

[lint.per-file-ignores]
"**/test_*.py" = ["RUF001"]
EOF

COPY lint/lint.sh /lint.sh
RUN chmod +x /lint.sh

CMD ["/lint.sh"]
