FROM ubuntu:22.04 as builder

RUN apt update \
    && apt upgrade -y \
    && apt install -y libpcre3 libpcre3-dev zlib1g zlib1g-dev openssl libssl-dev wget git gcc make libbrotli-dev

WORKDIR /app
RUN wget https://nginx.org/download/nginx-1.25.3.tar.gz && tar -zxf nginx-1.25.3.tar.gz
RUN git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli
RUN cd nginx-1.25.3 && ./configure --with-compat --add-dynamic-module=../ngx_brotli \
    && make modules


# Base image:
FROM nginx
# Install dependencies
RUN apt-get update -qq && apt-get -y install apache2-utils

COPY --from=builder /app/nginx-1.25.3/objs/ngx_http_brotli_static_module.so /etc/nginx/modules/
COPY --from=builder /app/nginx-1.25.3/objs/ngx_http_brotli_filter_module.so /etc/nginx/modules/

# establish where Nginx should look for files
ENV RAILS_APP_ROOT /app

# Set our working directory inside the image
WORKDIR /etc/nginx

RUN   sed -i '1 i\load_module modules/ngx_http_brotli_filter_module.so;' nginx.conf
RUN   sed -i '1 i\load_module modules/ngx_http_brotli_static_module.so;' nginx.conf


# Copy Nginx config template
COPY nginx.conf /tmp/docker.nginx

# substitute variable references in the Nginx config template for real values from the environment
# put the final config in its place
RUN envsubst '$RAILS_APP_ROOT' < /tmp/docker.nginx > /etc/nginx/conf.d/default.conf

EXPOSE 80

RUN mkdir -p $RAILS_APP_ROOT/log
RUN chown -R www-data:www-data $RAILS_APP_ROOT/log;
RUN chmod -R 755 $RAILS_APP_ROOT/log;

VOLUME [ "/app" ]

RUN cat /etc/nginx/nginx.conf

# Use the "exec" form of CMD so Nginx shuts down gracefully on SIGTERM (i.e. `docker stop`)
CMD [ "nginx", "-g", "daemon off;" ]