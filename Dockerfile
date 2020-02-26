FROM ubuntu AS base

ENV VERSION="1.8.12"

RUN apt-get update && apt-get -yq install \
    curl \
    libx11-dev \
    libxext-dev \
    libxrender-dev \
    libxtst-dev \
    unzip \
    xz-utils

WORKDIR /opt

RUN curl https://downloads.arduino.cc/arduino-$VERSION-linux64.tar.xz \
  | unxz \
  | tar --extract \
 && mv arduino-$VERSION arduino \
 && ./arduino/arduino-linux-setup.sh \
 && ./arduino/install.sh

FROM base AS drop-privileges
ENV USER=developer \
    UID=30132 \
    TEMPLATE=/developer/Arduino
# Whoever owns /developer/Arduino owns the instance

WORKDIR /developer

RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "$(pwd)" \
    --no-create-home \
    --uid "$UID" \
    "$USER" \
 && adduser "$USER" dialout \
 && mkdir -p "$TEMPLATE" \
 && chown -R "$USER":"$USER" .

ADD https://raw.githubusercontent.com/Rexypoo/docker-entrypoint-helper/master/entrypoint-helper.sh /usr/local/bin/entrypoint-helper.sh
RUN chmod u+x /usr/local/bin/entrypoint-helper.sh
ENTRYPOINT ["entrypoint-helper.sh", "/bin/bash"]
