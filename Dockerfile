FROM mariadb:11.4.3

RUN set -eux; \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    gcc \
    libc6-dev \
    make \
    libjemalloc-dev && \
  rm -rf /var/lib/apt/lists/*

ENV REDIS_VERSION=7.2.8

RUN rm -rf /var/lib/apt/lists/* && \
    cd /usr/local/src; wget -O redis.tar.gz https://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz && \
    tar -zxvf redis.tar.gz && \
  rm redis.tar.gz && \
  mv redis-${REDIS_VERSION} redis
  
RUN cd /usr/local/src/redis \
  make distclean && \
  make && \
  make install

RUN apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
  redis-cli --version; \
  redis-server --version

ADD https://github.com/jwilder/forego/releases/download/v0.16.1/forego /usr/local/bin/forego
RUN chmod +x /usr/local/bin/forego

EXPOSE 3306 6379

# Procfile（これでOK）
RUN echo "mariadb: /usr/local/bin/docker-entrypoint.sh mariadbd --verbose" > /Procfile
RUN echo "redis: redis-server --protected-mode no" >> /Procfile

RUN mkdir -p /etc/mysql/mariadb.conf.d
RUN echo "[mariadb]" > /etc/mysql/mariadb.conf.d/99-default-auth.cnf && \
    echo "default_authentication_plugin=mysql_native_password" >> /etc/mysql/mariadb.conf.d/99-default-auth.cnf

ENTRYPOINT [ "forego", "start", "-r" ]
