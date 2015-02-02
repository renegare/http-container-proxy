FROM        renegare/php:5.5.9

RUN         apt-get install -y make vim

RUN         curl -L  https://github.com/coreos/etcd/releases/download/v0.4.6/etcd-v0.4.6-linux-amd64.tar.gz \
                -o etcd-v0.4.6-linux-amd64.tar.gz && \
                tar xzvf etcd-v0.4.6-linux-amd64.tar.gz && \
                mv etcd-v0.4.6-linux-amd64/etcdctl /usr/local/bin/

RUN         rm -rf /var/www/html

COPY        env/healthcheck.html    /var/www/html/healthcheck/index.html
COPY        env/nginx.conf          /etc/nginx/nginx.conf
COPY        env/nginx-default       /etc/nginx/sites-enabled/default
COPY        .                       /var/app

WORKDIR     /var/app

RUN         rm -rf Makefile && \
                mv Makefile.prod Makefile

EXPOSE      80

ENTRYPOINT  ["/usr/bin/make", "-s"]
