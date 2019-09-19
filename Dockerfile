FROM php:7.0-cli-alpine

COPY dist /dist
RUN tar czf opencart-3.0.3.2.tgz -C /dist . && chmod o+r opencart-3.0.3.2.tgz

RUN apk update \
    && apk add mysql-client freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev \
    && docker-php-ext-configure gd --with-gd --with-freetype-dir=/usr/include/ --with-png-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install mysqli gd \
    && apk del freetype-dev libpng-dev libjpeg-turbo-dev

COPY install.sh /install
RUN chmod +x /install
WORKDIR /workdir
ENTRYPOINT ["/install"]
