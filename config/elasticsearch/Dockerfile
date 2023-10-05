FROM python:3.12-slim

COPY requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

ADD . /app

WORKDIR /app
ENTRYPOINT [ "python3", "apply_configuration.py", "es:9200", "--dev" ]

