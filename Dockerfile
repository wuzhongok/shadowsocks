FROM alpine:3.5

# grab su-exec for easy step-down from root
RUN apk add --no-cache 'su-exec>=0.2' ca-certificates
RUn mkdir -p /mnt

######################## start build python ########################
ENV PYTHON_M2CRYPTO_URL  https://pypi.python.org/packages/11/29/0b075f51c38df4649a24ecff9ead1ffc57b164710821048e3d997f1363b9/M2Crypto-0.26.0.tar.gz
RUN    apk add --no-cache python openssl openssl-dev
RUN set -ex \
    \
    && apk add --no-cache --virtual .build-deps \
        python-dev \
        py-pip \
        gcc \
        linux-headers \
        musl-dev \
        tar \
    \
    && pip install --upgrade pip  \
    && pip install redis \
    && cd /mnt \
    && mkdir -p /mnt/M2Crypto \
    && wget -O M2Crypto.tar.gz "$PYTHON_M2CRYPTO_URL" \
    && tar -xzf M2Crypto.tar.gz -C /mnt/M2Crypto --strip-components=1 \
    && cd /mnt/M2Crypto && python setup.py build && python setup.py install \
    && rm -rf /mnt/M2Crypto /mnt/M2Crypto.tar.gz \
    && apk del .build-deps
######################## finish build python ########################

######################## start build redis server ########################
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN addgroup -S redis && adduser -S -G redis redis

ENV REDIS_VERSION 3.2.8
ENV REDIS_DOWNLOAD_URL http://download.redis.io/releases/redis-3.2.8.tar.gz
ENV REDIS_DOWNLOAD_SHA1 6780d1abb66f33a97aad0edbe020403d0a15b67f

# for redis-sentinel see: http://redis.io/topics/sentinel
RUN set -ex \
    \
    && apk add --no-cache --virtual .build-deps \
        gcc \
        linux-headers \
        make \
        musl-dev \
        tar \
    \
    && wget -O redis.tar.gz "$REDIS_DOWNLOAD_URL" \
    && echo "$REDIS_DOWNLOAD_SHA1 *redis.tar.gz" | sha1sum -c - \
    && mkdir -p /usr/src/redis \
    && tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 \
    && rm redis.tar.gz \
    \
# Disable Redis protected mode [1] as it is unnecessary in context
# of Docker. Ports are not automatically exposed when running inside
# Docker, but rather explicitely by specifying -p / -P.
# [1] https://github.com/antirez/redis/commit/edd4d555df57dc84265fdfb4ef59a4678832f6da
    && grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 1$' /usr/src/redis/src/server.h \
    && sed -ri 's!^(#define CONFIG_DEFAULT_PROTECTED_MODE) 1$!\1 0!' /usr/src/redis/src/server.h \
    && grep -q '^#define CONFIG_DEFAULT_PROTECTED_MODE 0$' /usr/src/redis/src/server.h \
# for future reference, we modify this directly in the source instead of just supplying a default configuration flag because apparently "if you specify any argument to redis-server, [it assumes] you are going to specify everything"
# see also https://github.com/docker-library/redis/issues/4#issuecomment-50780840
# (more exactly, this makes sure the default behavior of "save on SIGTERM" stays functional by default)
    \
    && make -C /usr/src/redis \
    && make -C /usr/src/redis install \
    \
    && rm -r /usr/src/redis \
    \
    && apk del .build-deps

RUN mkdir -p /mnt/redis/data /mnt/redis/logs /mnt/redis/etc && chown redis:redis /mnt/redis
COPY rd_default.conf /mnt/redis/etc/rd_default.conf
EXPOSE 6370
CMD ["redis-server","/mnt/redis/etc/rd_default.conf"]
######################## finish build redis server ########################

######################## start build ss-py ########################
RUN    cd /mnt && mkdir -p server
COPY    ss-py-mu.tar.gz /mnt/server/ss-py-mu.tar.gz
RUN    cd /mnt/server && tar -zvxf ss-py-mu.tar.gz && rm -f ss-py-mu.tar.gz
######################## finish build ss-py ########################

RUN    cd /mnt && mkdir -p script logs
COPY    start.sh /mnt/script/start.sh
RUN    chmod -R +x /mnt/script
CMD    ["/mnt/script/start.sh"]
