FROM ps2dev/ps2dev:latest

# Install all necessary build tools for ports
RUN apk add --no-cache build-base git bash cmake autoconf automake libtool gettext-dev pkgconf flex bison

# 1. Build gsKit
WORKDIR /src
RUN git clone https://github.com/ps2dev/gsKit.git && \
    cd gsKit && \
    ./setup.sh

# 2. Build ps2sdk-ports (SDL, libmad, audsrv, sdl_mixer)
RUN git clone --recursive https://github.com/ps2dev/ps2sdk-ports.git && \
    cd ps2sdk-ports && \
    cd sdl && make && make install && cd .. && \
    cd libmad && make && make install && cd .. && \
    cd audsrv && make && make install && cd .. && \
    MIXER_DIR=$(find . -maxdepth 1 -type d -iname "*sdl_mixer*") && \
    cd "$MIXER_DIR" && \
    (if [ -f "Makefile" ]; then make && make install; elif [ -d "ee" ]; then cd ee && make && make install; fi)

# Cleanup source to keep image slim
RUN rm -rf /src/*

ENV GSKIT=/usr/local/ps2dev/gsKit
WORKDIR /src
