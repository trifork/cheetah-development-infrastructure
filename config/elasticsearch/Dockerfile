FROM python:3.8-slim

COPY requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

ADD . /app

WORKDIR /app
RUN chmod +x /app/docker-entrypoint.sh

CMD [ "python3", "apply_configuration.py", "es:9200", "--dev" ]
ENTRYPOINT [ "bash", "/app/docker-entrypoint.sh" ]
