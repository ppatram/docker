#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#
FROM ubuntu:latest

LABEL maintainer="Parmanand Patram <ppatram@gmail.com>"

COPY install.sh /

RUN set -x \
    && chmod 755 install.sh \
    && ./install.sh


COPY startup.sh /

ENTRYPOINT ["/startup.sh"]

EXPOSE 80

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
