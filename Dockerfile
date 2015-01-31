FROM renegare/php:5.5.9

RUN apt-get install -y make

COPY . /var/www

WORKDIR /var/www

EXPOSE 80

RUN rm -rf Makefile && \
    mv Makefile.prod Makefile

ENTRYPOINT ["/usr/bin/make", "-s"]
