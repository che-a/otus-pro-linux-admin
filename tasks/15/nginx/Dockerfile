FROM alpine:3.10
LABEL version="1.1" \
      description="OTUS Linux Admin. Lesson 15. Custom NGINX-image on Alpine." \
      author="Chernyshenko Aleksey"
RUN apk add --update --no-cache nginx \
&& adduser -D -g 'www' www \
&& mkdir /www && mkdir -p /run/nginx
ADD https://raw.githubusercontent.com/che-a/OTUS_LinuxAdministrator/master/tasks/15/nginx/nginx.conf /etc/nginx/
ADD https://raw.githubusercontent.com/che-a/OTUS_LinuxAdministrator/master/tasks/15/nginx/index.html /www/
RUN chown -R www:www /var/lib/nginx && chown -R www:www /www
EXPOSE 80
STOPSIGNAL SIGTERM
CMD ["nginx", "-g", "daemon off;"]
