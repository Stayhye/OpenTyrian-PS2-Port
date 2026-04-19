# Stage 1: Build dependencies
FROM ps2dev/ps2dev:latest AS builder

# Install build tools
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
    # Using a wildcard to find the mixer directory
    cd $(find . -maxdepth 1 -type d -iname "*sdl_mixer*") && \
    (if [ -f "Makefile" ]; then make && make install; elif [ -d "ee" ]; then cd ee && make && make install; fi)

# Stage 2: Final Image
FROM ps2dev/ps2dev:latest

# Copy the compiled libraries and headers from the builder stage
COPY --from=builder /usr/local/ps2dev /usr/local/ps2dev

# Set environment variables
ENV PS2DEV=/usr/local/ps2dev
ENV PS2SDK=$PS2DEV/ps2sdk
ENV GSKIT=$PS2DEV/gsKit
ENV PATH=$PATH:$PS2DEV/bin:$PS2SDK/bin

WORKDIR /src
