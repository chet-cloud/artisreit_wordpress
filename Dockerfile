FROM bitnami/nginx:1.21-debian-10 AS builder
USER root
## Redeclare NGINX_VERSION so it can be used as a parameter inside this build stage
ENV NGINX_VERSION=1.21.5
## Install required packages and build dependencies
RUN install_packages dirmngr gpg gpg-agent curl build-essential zlib1g-dev libperl-dev
## perl libperl-dev libgd3 libgd-dev libgeoip1 libgeoip-dev geoip-bin libxml2 libxml2-dev libxslt1.1 libxslt1-dev
## Add trusted NGINX PGP key for tarball integrity verification
RUN gpg --keyserver pgp.mit.edu --recv-key 520A9993A1C052F8
## Download NGINX, verify integrity and extract
RUN cd /tmp && \
    curl -O http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    curl -O http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz.asc && \
    gpg --verify nginx-${NGINX_VERSION}.tar.gz.asc nginx-${NGINX_VERSION}.tar.gz && \
    tar xzf nginx-${NGINX_VERSION}.tar.gz

RUN cd /tmp && \
    curl -L https://github.com/chet-cloud/ngx_cache_purge/archive/refs/tags/2.3-fix.tar.gz > ngx_cache_purge-2.3.tar && \
    tar -xf ngx_cache_purge-2.3.tar

## Compile NGINX with desired module
RUN cd /tmp/nginx-${NGINX_VERSION} && \
    rm -rf /opt/bitnami/nginx && \
    ./configure --prefix=/opt/bitnami/nginx --with-compat --add-dynamic-module=/tmp/ngx_cache_purge-2.3-fix && \
    make && \
    make install

###############################################################

FROM bitnami/wordpress-nginx:5.9.3
LABEL maintainer "Bitnami <containers@bitnami.com>"

## Change user to perform privileged actions
USER 0
## Install 'vim'
RUN install_packages vim

# for nginx
COPY --from=builder /opt/bitnami/nginx/modules/ngx_http_cache_purge_module.so /opt/bitnami/nginx/modules/ngx_http_cache_purge_module.so
## Enable module
RUN echo "load_module modules/ngx_http_cache_purge_module.so;" | cat - /opt/bitnami/nginx/conf/nginx.conf > /tmp/nginx.conf && \
     cp /tmp/nginx.conf /opt/bitnami/nginx/conf/nginx.conf

## Revert to the original non-root user
USER 1001

## Modify the ports used by NGINX by default
# It is also possible to change these environment variables at runtime
ENV NGINX_HTTP_PORT_NUMBER=8080
ENV NGINX_HTTPS_PORT_NUMBER=8443
EXPOSE 8080 8443

###############################################################

#FROM docker.io/bitnami/minideb:buster
#LABEL maintainer "Bitnami <containers@bitnami.com>"
#
#ENV HOME="/" \
#    OS_ARCH="amd64" \
#    OS_FLAVOUR="debian-10" \
#    OS_NAME="linux"
#
#COPY prebuildfs /
## Install required system packages and dependencies
#RUN install_packages acl ca-certificates curl gzip less libaudit1 libbsd0 libbz2-1.0 libc6 libcap-ng0 libcom-err2 libcurl4 libexpat1 libffi6 libfftw3-double3 libfontconfig1 libfreetype6 libgcc1 libgcrypt20 libgeoip1 libglib2.0-0 libgmp10 libgnutls30 libgomp1 libgpg-error0 libgssapi-krb5-2 libhogweed4 libicu63 libidn2-0 libjemalloc2 libjpeg62-turbo libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 liblcms2-2 libldap-2.4-2 liblqr-1-0 libltdl7 liblzma5 libmagickcore-6.q16-6 libmagickwand-6.q16-6 libmcrypt4 libmemcached11 libmemcachedutil2 libncurses6 libnettle6 libnghttp2-14 libonig5 libp11-kit0 libpam0g libpcre3 libpng16-16 libpq5 libpsl5 libreadline7 librtmp1 libsasl2-2 libsodium23 libsqlite3-0 libssh2-1 libssl1.1 libstdc++6 libsybdb5 libtasn1-6 libtidy5deb1 libtinfo6 libunistring2 libuuid1 libwebp6 libx11-6 libxau6 libxcb1 libxdmcp6 libxext6 libxml2 libxslt1.1 libzip4 procps tar zlib1g
#RUN . /opt/bitnami/scripts/libcomponent.sh && component_unpack "render-template" "1.0.1-5" --checksum 9e312b4a7e16a55d08e67c4fd69c91000e4dcc4af149d59915c49375b83852af
#RUN . /opt/bitnami/scripts/libcomponent.sh && component_unpack "php" "7.4.27-8" --checksum 91191e8bdf140a08f873675198c998fa4fabbea0a22fce0791568b5f8c11aaad
#RUN . /opt/bitnami/scripts/libcomponent.sh && component_unpack "wp-cli" "2.5.0-2" --checksum a2378193012ec330be563c1160e8dcfa8576a4c929858ae2d691926d0be6635a
#RUN . /opt/bitnami/scripts/libcomponent.sh && component_unpack "nginx" "1.21.5-2" --checksum 947761e123cc60d01e9de9a5067f41d5f265f502814a62919e2bde61004c5b27
#
## for nginx
#COPY --from=builder /opt/bitnami/nginx/modules/ngx_http_cache_purge_module.so /opt/bitnami/nginx/modules/ngx_http_cache_purge_module.so
### Enable module
#RUN echo "load_module modules/ngx_http_cache_purge_module.so;" | cat - /opt/bitnami/nginx/conf/nginx.conf > /tmp/nginx.conf && \
#     cp /tmp/nginx.conf /opt/bitnami/nginx/conf/nginx.conf
#
#
#RUN . /opt/bitnami/scripts/libcomponent.sh && component_unpack "mysql-client" "10.3.32-1" --checksum 727834a55587746f90b159966c9abf2ce31a6effbe83d8c38ee6250641c9a22a
#RUN . /opt/bitnami/scripts/libcomponent.sh && component_unpack "wordpress" "5.8.3-4" --checksum 22186e22cc63222a0a18261a0ebe80bce10e62dba8f69f92cf87ae18762812f5
#RUN . /opt/bitnami/scripts/libcomponent.sh && component_unpack "gosu" "1.14.0-2" --checksum 7419bc5e2be68eb14c92e321acc843413481cda73323fb8c0d1dda8b1e5aa9d5
#RUN apt-get update && apt-get upgrade -y && \
#    rm -r /var/lib/apt/lists /var/cache/apt/archives
#RUN chmod g+rwX /opt/bitnami
#
#COPY rootfs /
#RUN /opt/bitnami/scripts/mysql-client/postunpack.sh
#RUN /opt/bitnami/scripts/php/postunpack.sh
#RUN /opt/bitnami/scripts/nginx/postunpack.sh
#RUN /opt/bitnami/scripts/nginx-php-fpm/postunpack.sh
#RUN /opt/bitnami/scripts/wordpress/postunpack.sh
#RUN /opt/bitnami/scripts/wp-cli/postunpack.sh
#ENV BITNAMI_APP_NAME="wordpress-nginx" \
#    BITNAMI_IMAGE_VERSION="5.8.3-debian-10-r10" \
#    NGINX_HTTPS_PORT_NUMBER="" \
#    NGINX_HTTP_PORT_NUMBER="" \
#    PATH="/opt/bitnami/common/bin:/opt/bitnami/php/bin:/opt/bitnami/php/sbin:/opt/bitnami/wp-cli/bin:/opt/bitnami/nginx/sbin:/opt/bitnami/mysql/bin:$PATH"
#
#EXPOSE 8080 8443
#
#USER 1001
#ENTRYPOINT [ "/opt/bitnami/scripts/wordpress/entrypoint.sh" ]
#CMD [ "/opt/bitnami/scripts/nginx-php-fpm/run.sh" ]
