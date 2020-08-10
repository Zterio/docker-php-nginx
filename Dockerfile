FROM alpine:3.12
LABEL Maintainer="Zterio <Zterio@i5.io>" \
      Description="still an progress from a fork "

#Set up timezone

ARG TimeZone='Europe/Oslo'

ENV DEFAULT_TIMEZONE ${TimeZone}

RUN apk upgrade --update && apk add -U tzdata 
 
RUN cp /usr/share/zoneinfo/${DEFAULT_TIMEZONE} /etc/localtime

# Install packages and remove default server definition
RUN apk --no-cache add php7 php7-fpm php7-opcache php7-mysqli php7-json php7-openssl php7-curl \
    php7-zlib php7-xml php7-phar php7-intl php7-dom php7-xmlreader php7-ctype php7-session \
    php7-mbstring php7-gd nginx supervisor curl git wget && \
    rm /etc/nginx/conf.d/default.conf

# Create Site config folder
RUN mkdir -p /app
RUN mkdir -p /app/config
RUN mkdir -p /app/web


# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/custom.ini


#Set up composer
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /app && \
  chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Add application
WORKDIR /app/web
#COPY --chown=nobody src/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 80
EXPOSE 443

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
