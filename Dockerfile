FROM ubuntu:20.04
ARG gosu_ver=1.12
ARG TARGETARCH

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TZ=UTC \
    CLICKHOUSE_CONFIG=/etc/clickhouse-server/config.xml

RUN mkdir /docker-entrypoint-initdb.d \
    && mkdir /var/lib/clickhouse \
    && mkdir -p /etc/clickhouse-server/config.d/

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    dirmngr \
    gnupg \
    locales \
    wget \
    && rm -rf \
    /var/lib/apt/lists/* \
    /var/cache/debconf \
    /tmp/* \
    && apt-get clean

COPY config.xml /etc/clickhouse-server/
COPY users.xml /etc/clickhouse-server/
COPY docker_related_config.xml /etc/clickhouse-server/config.d/
COPY entrypoint.sh /entrypoint.sh

RUN groupadd -r clickhouse --gid=999 \
    && useradd -r -g clickhouse --uid=999 --home-dir=/nonexistent --shell=/bin/false clickhouse \
    && chown -R clickhouse:clickhouse /var/lib/clickhouse \
    && chown -R clickhouse:clickhouse /etc/clickhouse-server

ADD https://github.com/tianon/gosu/releases/download/$gosu_ver/gosu-${TARGETARCH} /bin/gosu

COPY clickhouse-${TARGETARCH} /usr/bin/clickhouse
RUN chmod +x /usr/bin/clickhouse
RUN command -v setcap >/dev/nul && setcap 'cap_net_admin,cap_ipc_lock,cap_sys_nice+ep' /usr/bin/clickhouse
RUN ln -s /usr/bin/clickhouse /usr/bin/clickhouse-server 

RUN chmod +x \
    /entrypoint.sh \
    /bin/gosu

EXPOSE 9000 8123 9009
VOLUME /var/lib/clickhouse

ENTRYPOINT ["/entrypoint.sh"]
