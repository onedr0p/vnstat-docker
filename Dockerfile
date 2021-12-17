FROM alpine:latest AS base

LABEL author="Teemu Toivola"
LABEL repository.git="https://github.com/vergoh/vnstat-docker"
LABEL repository.docker="https://hub.docker.com/r/vergoh/vnstat"

ENV HTTP_PORT=8586
ENV HTTP_BIND=*
ENV HTTP_LOG=/dev/stdout
ENV LARGE_FONTS=0
ENV CACHE_TIME=1
ENV RATE_UNIT=1
ENV PAGE_REFRESH=0

RUN true \
    && set -ex \
    && apk add --no-cache \
                gd \
                perl \
                lighttpd \
                sqlite-libs \
                curl


FROM alpine:latest AS builder

RUN true \
    && set -ex \
    && apk add --no-cache \
                gcc \
                make \
                musl-dev \
                linux-headers \
                gd-dev \
                sqlite-dev \
    && wget https://humdi.net/vnstat/vnstat-latest.tar.gz \
    && tar zxvf vnstat-latest.tar.gz \
    && cd vnstat-*/ \
    && ./configure --prefix=/usr --sysconfdir=/etc \
    && make && make install


FROM base AS runtime

COPY --from=builder /usr/bin/vnstat /usr/bin/vnstat
COPY --from=builder /usr/bin/vnstati /usr/bin/vnstati
COPY --from=builder /usr/sbin/vnstatd /usr/sbin/vnstatd
COPY --from=builder /etc/vnstat.conf /etc/vnstat.conf

RUN true \
    && set -ex \
    && addgroup -S vnstat  \
    && adduser -S -h /var/lib/vnstat -s /sbin/nologin -g vnStat -D -H -G vnstat vnstat

COPY favicon.ico /var/www/localhost/htdocs/favicon.ico
COPY start.sh /
COPY vnstat.cgi /var/www/localhost/htdocs/index.cgi
COPY vnstat-json.cgi /var/www/localhost/htdocs/json.cgi

VOLUME /var/lib/vnstat
EXPOSE ${HTTP_PORT}

CMD [ "/start.sh" ]
HEALTHCHECK CMD curl --silent --fail http://localhost:${HTTP_PORT}/ || exit 1