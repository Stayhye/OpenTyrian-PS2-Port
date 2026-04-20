FROM ps2dev/ps2dev:latest

# Install build tools
RUN apk add --no-cache build-base git bash cmake autoconf automake libtool gettext-dev pkgconf flex bison

WORKDIR /src

# 1. Build gsKit
RUN git clone https://github.com/ps2dev/gsKit.git && \
    cd gsKit && \
    ./setup.sh

# 2. Clone Ports (Recursive)
RUN git clone --recursive https://github.com/ps2dev/ps2sdk-ports.git

# 3. Build SDL
RUN cd /src/ps2sdk-ports/sdl && \
    make -j$(nproc) && make install

# 4. Build libmad
RUN cd /src/ps2sdk-ports/libmad && \
    make -j$(nproc) && make install

# 5. Build SDL_mixer (The surgical fix)
# We go directly into the SDL_mixer directory and build ONLY the EE library
RUN cd /src/ps2sdk-ports && \
    MIX_DIR=$(find . -maxdepth 2 -type d -iname "*sdl_mixer*" | head -n 1) && \
    cd "$MIX_DIR" && \
    # If there is an 'ee' folder, that's the one we want for the PS2's main CPU
    if [ -d "ee" ]; then cd ee; fi && \
    make -j$(nproc) && make install

# Cleanup
RUN rm -rf /src/*

# Environment variables
ENV GSKIT=/usr/local/ps2dev/gsKit
ENV PS2DEV=/usr/local/ps2dev
ENV PS2SDK=$PS2DEV/ps2sdk
ENV PATH=$PATH:$PS2DEV/bin:$PS2SDK/bin

WORKDIR /src
