FROM ps2dev/ps2dev:latest

# Install build tools
RUN apk add --no-cache build-base git bash cmake autoconf automake libtool gettext-dev pkgconf flex bison

WORKDIR /src

# 1. Build gsKit
RUN git clone https://github.com/ps2dev/gsKit.git && \
    cd gsKit && \
    ./setup.sh

# 2. Clone Ports
RUN git clone --recursive https://github.com/ps2dev/ps2sdk-ports.git

# 3. Build SDL (Core dependency)
RUN cd /src/ps2sdk-ports && \
    DIR=$(find . -maxdepth 2 -type d -iname "sdl" | head -n 1) && \
    cd "$DIR" && make -j$(nproc) && make install

# 4. Build libmad (Required for OpenTyrian MP3/Audio)
RUN cd /src/ps2sdk-ports && \
    DIR=$(find . -maxdepth 2 -type d -iname "libmad" | head -n 1) && \
    cd "$DIR" && make -j$(nproc) && make install

# 5. Build SDL_mixer
# We skip audsrv because it's built into the modern PS2SDK
RUN cd /src/ps2sdk-ports && \
    MIX_DIR=$(find . -maxdepth 2 -type d -iname "*sdl_mixer*" | head -n 1) && \
    cd "$MIX_DIR" && \
    if [ -f "Makefile" ]; then \
        make -j$(nproc) && make install; \
    elif [ -d "ee" ]; then \
        cd ee && make -j$(nproc) && make install; \
    fi

# Cleanup
RUN rm -rf /src/*

# Environment variables
ENV GSKIT=/usr/local/ps2dev/gsKit
ENV PS2DEV=/usr/local/ps2dev
ENV PS2SDK=$PS2DEV/ps2sdk
ENV PATH=$PATH:$PS2DEV/bin:$PS2SDK/bin

WORKDIR /src
