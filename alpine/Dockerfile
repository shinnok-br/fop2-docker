FROM alpine:3.8

RUN apt-get update

RUN apt-get update && apt-get install -y wget default-jre emacs apache2 build-essential mysql-client

COPY fop2 /usr/share/fop2
ADD ports.conf /etc/apache2/
RUN cd /usr/share/fop2/ ; make install

COPY pre-init.d /usr/local/fop2/pre-init.d/
ADD buttons.cfg /usr/local/fop2/

ENTRYPOINT ["/usr/local/fop2/run.sh"]

CMD ["/usr/local/fop2/fop2_server"]
