FROM ps2dev/ps2dev:latest

# Install build tools
RUN apk add --no-cache build-base git bash cmake autoconf automake libtool gettext-dev pkgconf flex bison

WORKDIR /src

# 1. Build gsKit
RUN git clone https://github.com/ps2dev/gsKit.git && \
    cd gsKit && \
    ./setup.sh

# 2. Build ps2sdk-ports
RUN git clone --recursive https://github.com/ps2dev/ps2sdk-ports.git && \
    cd ps2sdk-ports && \
    # Build SDL
    cd $(find . -maxdepth 2 -type d -iname "sdl") && make && make install && \
    cd /src/ps2sdk-ports && \
    # Build libmad
    cd $(find . -maxdepth 2 -type d -iname "libmad") && make && make install && \
    cd /src/ps2sdk-ports && \
    # Build audsrv
    cd $(find . -maxdepth 2 -type d -iname "audsrv") && make && make install && \
    cd /src/ps2sdk-ports && \
    # Build SDL_mixer
    cd $(find . -maxdepth 2 -type d -iname "*sdl_mixer*") && \
    (if [ -f "Makefile" ]; then make && make install; elif [ -d "ee" ]; then cd ee && make && make install; fi)

# Cleanup source to keep image slim
RUN rm -rf /src/*

ENV GSKIT=/usr/local/ps2dev/gsKit
WORKDIR /src
