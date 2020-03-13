FROM ubuntu AS base

ENV VERSION="1.8.12"

RUN apt-get update && apt-get -yq install \
    curl \
    libx11-dev \
    libxext-dev \
    libxrender-dev \
    libxtst-dev \
    sudo \
    systemd \
    udev \
    unzip \
    xz-utils

WORKDIR /opt

RUN curl https://downloads.arduino.cc/arduino-$VERSION-linux64.tar.xz \
  | unxz \
  | tar --extract \
 && mv arduino-$VERSION arduino \
 && ./arduino/install.sh \
 && ./arduino/arduino-linux-setup.sh root

FROM base AS drop-privileges
ENV USER=developer \
    UID=30132 \
    TEMPLATE=/developer/Arduino
# Whoever owns /developer/Arduino owns the instance

WORKDIR /"$USER"

RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "$(pwd)" \
    --no-create-home \
    --uid "$UID" \
    "$USER" \
 && adduser "$USER" dialout \
 && adduser "$USER" plugdev \
 && adduser "$USER" tty \
 && adduser "$USER" uucp \
 && mkdir -p "$TEMPLATE" \
 && chown -R "$USER":"$USER" .

ADD https://raw.githubusercontent.com/Rexypoo/docker-entrypoint-helper/master/entrypoint-helper.sh /usr/local/bin/entrypoint-helper.sh
RUN chmod u+x /usr/local/bin/entrypoint-helper.sh

# I'm having a big problem with environment variables for the user
# I wish I knew a better way than this hack
RUN sed -i 's/echo >>/echo "export LC_ALL=C.UTF-8; export LANG=C.UTF-8;" >>/' /usr/local/bin/entrypoint-helper.sh

ENTRYPOINT ["entrypoint-helper.sh", "arduino"]

# Build with 'docker build -t arduino .'
LABEL org.opencontainers.image.url="https://hub.docker.com/r/rexypoo/arduino" \
      org.opencontainers.image.documentation="https://hub.docker.com/r/rexypoo/arduino" \
      org.opencontainers.image.source="https://github.com/Rexypoo/docker-arduino" \
      org.opencontainers.image.version="0.1a" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.description="Arduino on Docker" \
      org.opencontainers.image.title="rexypoo/arduino" \
      org.label-schema.docker.cmd='mkdir -p "$HOME"/Arduino && \
      docker run -d --rm \
      --name arduino \
      --env DISPLAY \
      --volume /tmp/.X11-unix:/tmp/.X11-unix:ro \
      --volume "$HOME"/Arduino:/developer/Arduino \
      --device /dev/ttyACM0 \
      rexypoo/arduino' \
      org.label-schema.docker.cmd.devel="docker run -it --rm --entrypoint bash rexypoo/arduino" \
      org.label-schema.docker.cmd.debug="docker exec -it arduino bash"
