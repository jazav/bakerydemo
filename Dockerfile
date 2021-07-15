#latest python
FROM python:slim

# Install packages needed to run your application (not build deps):
# We need to recreate the /usr/share/man/man{1..8} directories first because
# they were clobbered by a parent image.
RUN set -ex \
    && RUN_DEPS=" \
        libexpat1 \
        libjpeg62-turbo \
        libpcre3 \
        libpq5 \
        mime-support \
        postgresql-client \
        procps \
        zlib1g \
    " \
    && seq 1 8 | xargs -I{} mkdir -p /usr/share/man/man{} \
    && apt-get update && apt-get install -y --no-install-recommends $RUN_DEPS \
    && rm -rf /var/lib/apt/lists/*

ADD requirements/ /requirements/
RUN set -ex \
    && BUILD_DEPS=" \
        build-essential \
        git \
        libexpat1-dev \
        libjpeg62-turbo-dev \
        libpcre3-dev \
        libpq-dev \
        zlib1g-dev \
    " \
    && apt-get update && apt-get install -y --no-install-recommends $BUILD_DEPS \
    && python3 -m venv /venv \
    && /venv/bin/pip install -U pip \
    && /venv/bin/pip install -U setuptools \
    && /venv/bin/pip install --no-cache-dir -r /requirements/production.txt \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $BUILD_DEPS \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /code/
WORKDIR /code/
ADD . /code/
# we need it here or in docker-compose to docker-gen
#EXPOSE 3031

# Add custom environment variables needed by Django or your settings file here:
ENV DJANGO_SETTINGS_MODULE=bakerydemo.settings.production DJANGO_DEBUG=on

# Tell uWSGI where to find your wsgi file:
#!ENV UWSGI_WSGI_FILE=bakerydemo/wsgi.py

# Base uWSGI configuration (you shouldn't need to change these):
#!ENV UWSGI_VIRTUALENV=/venv UWSGI_HTTP=:8000 UWSGI_MASTER=1 UWSGI_HTTP_AUTO_CHUNKED=1 UWSGI_HTTP_KEEPALIVE=1 UWSGI_UID=1000 UWSGI_GID=2000 UWSGI_LAZY_APPS=1 UWSGI_WSGI_ENV_BEHAVIOR=holy
#!ENV UWSGI_LOGTO=/var/log/uwsgi/uwsgi.log

# AZ define socket to interchange between uwsgi and nginx
# unix socket
#ENV UWSGI_SOCKET="/tmp/uwsgi.sock"
# tcp socket
#!ENV UWSGI_SOCKET=:3031

# env for https://hub.docker.com/r/nginxproxy/nginx-proxy
# http or uwsgi
#!ENV VIRTUAL_PROTO=uwsgi

# Number of uWSGI workers and threads per worker (customize as needed):
#!ENV UWSGI_WORKERS=2 UWSGI_THREADS=4

# uWSGI uploaded media file serving configuration:
#!ENV UWSGI_STATIC_MAP="/media/=/code/bakerydemo/media/"

# Call collectstatic with dummy environment variables:
RUN DATABASE_URL=postgres://none REDIS_URL=none /venv/bin/python manage.py collectstatic --noinput

# make sure static files are writable by uWSGI process
RUN mkdir -p /code/bakerydemo/media/images && chown -R 1000:2000 /code/bakerydemo/media

# mark the destination for images as a volume
VOLUME ["/code/bakerydemo/media/images/"]

# start uWSGI, using a wrapper script to allow us to easily add more commands to container startup:
ENTRYPOINT ["/code/docker-entrypoint.sh"]

# AZ
LABEL application=bakery

# Start uWSGI
# have a look: https://www.techatbloomberg.com/blog/configuring-uwsgi-production-deployment/
# --strict - This option tells uWSGI to fail to start if any parameter in the configuration file isn’t explicitly
# understood by uWSGI.
# --master - The master uWSGI process is necessary to gracefully re-spawn and pre-fork workers, consolidate logs,
# and manage many other features (shared memory, cron jobs, worker timeouts…). Without this feature on,
# uWSGI is a mere shadow of its true self.
# --vacuum - This option will instruct uWSGI to clean up any temporary files or UNIX sockets it created,
# such as HTTP sockets, pidfiles, or admin FIFOs.
#"--disable-logging", "--chmod-socket=666"
#CMD ["/venv/bin/uwsgi", "--strict", "--show-config", "--enable-threads", "--single-interpreter", "--vacuum", "--need-app", "--master", "--die-on-term", "--auto-procname", "--log-4xx", "--log-5xx"]
CMD ["/venv/bin/uwsgi", "--strict", "--show-config", "./uwsgi.ini"]