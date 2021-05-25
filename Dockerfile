FROM alpine:latest

ENV HTTP_PORT=8586
ENV HTTP_LOG=/dev/stdout
ENV LARGE_FONTS=0
ENV CACHE_TIME=1
ENV RATE_UNIT=1

RUN apk add --no-cache gcc musl-dev make perl gd gd-dev sqlite-libs sqlite-dev thttpd && \
  sed -i -e '/^chroot/d' -e '/^vhost/d' -e '/^logfile/d' /etc/thttpd.conf && \
  wget https://humdi.net/vnstat/vnstat-latest.tar.gz && \
  tar zxvf vnstat-latest.tar.gz && \
  cd vnstat-*/ && \
  ./configure --prefix=/usr --sysconfdir=/etc && \
  make && make install && \
  cd .. && rm -fr vnstat* && \
  apk del gcc pkgconf gd-dev make musl-dev sqlite-dev

COPY vnstat.cgi /var/www/http/index.cgi
COPY vnstat-json.cgi /var/www/http/json.cgi

VOLUME /var/lib/vnstat
EXPOSE ${HTTP_PORT}

COPY start.sh /
CMD /start.sh
