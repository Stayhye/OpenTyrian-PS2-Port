FROM ps2dev/ps2dev:latest

# Install build tools
RUN apk add --no-cache build-base git bash cmake autoconf automake libtool gettext-dev pkgconf flex bison

WORKDIR /src

# 1. Build gsKit
RUN git clone https://github.com/ps2dev/gsKit.git && \
    cd gsKit && \
    ./setup.sh

# 2. Clone Ports (Recursive is required for the submodules)
RUN git clone --recursive https://github.com/ps2dev/ps2sdk-ports.git

# 3. Build SDL
RUN cd /src/ps2sdk-ports && \
    DIR=$(find . -maxdepth 2 -type d -iname "sdl" | head -n 1) && \
    cd "$DIR" && make && make install

# 4. Build libmad
RUN cd /src/ps2sdk-ports && \
    DIR=$(find . -maxdepth 2 -type d -iname "libmad" | head -n 1) && \
    cd "$DIR" && make && make install

# 5. Build audsrv
RUN cd /src/ps2sdk-ports && \
    DIR=$(find . -maxdepth 2 -type d -iname "audsrv" | head -n 1) && \
    cd "$DIR" && make && make install

# 6. Build SDL_mixer
# This handles the nested 'ee' folder structure found in many SDL_mixer ports
RUN cd /src/ps2sdk-ports && \
    MIX_DIR=$(find . -maxdepth 2 -type d -iname "*sdl_mixer*" | head -n 1) && \
    cd "$MIX_DIR" && \
    if [ -f "Makefile" ]; then \
        make && make install; \
    elif [ -d "ee" ]; then \
        cd ee && make && make install; \
    else \
        echo "Could not find a valid Makefile for SDL_mixer" && exit 1; \
    fi

# Cleanup source to keep the image size down
RUN rm -rf /src/*

# Set environment variables for the game build
ENV GSKIT=/usr/local/ps2dev/gsKit
ENV PS2DEV=/usr/local/ps2dev
ENV PS2SDK=$PS2DEV/ps2sdk
ENV PATH=$PATH:$PS2DEV/bin:$PS2SDK/bin

WORKDIR /src
