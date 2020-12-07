FROM nginx:1.18.0

ENV NGINX_VERSION     "1.18.0"
ENV NGINX_VTS_VERSION "0.1.18"

RUN apt-get update && apt-get install -y --no-install-recommends lsb-release
RUN echo "deb-src http://nginx.org/packages/debian/ $(lsb_release -cs) nginx" >> /etc/apt/sources.list \
  # If you add souce, you have to update
  && apt-get update \
  && apt-get install -y dpkg-dev curl \
  && mkdir -p /opt/rebuildnginx \
  && chmod 0777 /opt/rebuildnginx \
  && cd /opt/rebuildnginx \
  && su --preserve-environment -s /bin/bash -c "apt-get source nginx" _apt \
  # Install package dependencies
  && apt-get build-dep -y nginx=${NGINX_VERSION}

RUN cd /opt \
  && curl -sL https://github.com/vozlt/nginx-module-vts/archive/v${NGINX_VTS_VERSION}.tar.gz | tar -xz \
  && ls -al /opt/rebuildnginx \
  && ls -al /opt \
  && sed -i -r -e "s/\.\/configure(.*)/.\/configure\1 --add-module=\/opt\/nginx-module-vts-${NGINX_VTS_VERSION}/" /opt/rebuildnginx/nginx-${NGINX_VERSION}/debian/rules \
  # Build package
  && cd /opt/rebuildnginx/nginx-${NGINX_VERSION} \
  && dpkg-buildpackage -b \
  # Packages(.deb) files will be created at / location (not in the NGINX source directory)
  # Install package
  && cd /opt/rebuildnginx \
  && dpkg --install nginx_${NGINX_VERSION}-2~$(lsb_release -cs)_amd64.deb \
  && apt-get remove --purge -y dpkg-dev curl && apt-get -y --purge autoremove && rm -rf /var/lib/apt/lists/* && rm -rf /opt/*

COPY ./default.conf /etc/nginx/conf.d/default.conf

CMD ["nginx", "-g", "daemon off;"]
