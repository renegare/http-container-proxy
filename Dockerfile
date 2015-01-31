FROM        renegare/php:5.5.9

RUN         apt-get install -y make

COPY        env/healthcheck.html /var/www/html/healthcheck/index.html
COPY        . /var/app

WORKDIR     /var/app

RUN         rm -rf Makefile && \
                mv Makefile.prod Makefile

EXPOSE      80

ENTRYPOINT  ["/usr/bin/make", "-s"]
