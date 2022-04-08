# Base image:
FROM nginx
# Install dependencies
RUN apt-get update -qq && apt-get -y install apache2-utils

# establish where Nginx should look for files
ENV RAILS_APP_ROOT /app

# Set our working directory inside the image
WORKDIR /etc/nginx


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

# Use the "exec" form of CMD so Nginx shuts down gracefully on SIGTERM (i.e. `docker stop`)
CMD [ "nginx", "-g", "daemon off;" ]