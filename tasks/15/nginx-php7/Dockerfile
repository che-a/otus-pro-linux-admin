FROM alpine:3.10
LABEL version="1.4" \
      description="OTUS Linux Admin. Lesson 15. Custom image NGINX+PHP7 on Alpine." \
      author="Chernyshenko Aleksey"
RUN apk add --update --no-cache nginx \
&& apk add tzdata \
php7-fpm php7-mcrypt php7-soap php7-openssl php7-gmp php7-pdo_odbc php7-json \
php7-dom php7-pdo php7-zip php7-mysqli php7-sqlite3 php7-apcu php7-pdo_pgsql \
php7-bcmath php7-gd php7-odbc php7-pdo_mysql php7-pdo_sqlite php7-gettext \
php7-xmlreader php7-xmlrpc php7-bz2 php7-iconv php7-pdo_dblib php7-curl \
php7-ctype \
&& adduser -D -g 'www' www \
&& mkdir /www \
&& mkdir -p /run/nginx \
&& TIMEZONE="Europe/Moscow" \
&& cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
&& echo "${TIMEZONE}" > /etc/timezone \
&& sed -i "s|;*date.timezone =.*|date.timezone = ${TIMEZONE}|i" /etc/php7/php.ini
ADD https://raw.githubusercontent.com/che-a/OTUS_LinuxAdministrator/master/tasks/15/nginx-php7/nginx.conf /etc/nginx/
ADD https://raw.githubusercontent.com/che-a/OTUS_LinuxAdministrator/master/tasks/15/nginx-php7/phpinfo.php /www/
RUN chown -R www:www /var/lib/nginx && chown -R www:www /www
EXPOSE 80
STOPSIGNAL SIGTERM
CMD ["nginx", "-g", "daemon off;"]
