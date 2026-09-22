FROM python:3.12-slim

WORKDIR /workspace

RUN pip install --no-cache-dir "isort>=5.0.0" "black>=24.0.0" "docformatter>=1.7.5"

COPY reformat/reformat.sh /reformat.sh
RUN chmod +x /reformat.sh

CMD ["/reformat.sh"]
