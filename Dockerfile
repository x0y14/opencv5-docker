FROM ubuntu:bionic

# ffmpeg install
RUN apt update -qq && apt -y install \
  autoconf \
  automake \
  build-essential \
  git \
  libass-dev \
  libfreetype6-dev \
  libgnutls28-dev \
  libsdl2-dev \
  libtool \
  libva-dev \
  libvdpau-dev \
  libvorbis-dev \
  libxcb1-dev \
  libxcb-shm0-dev \
  libxcb-xfixes0-dev \
  meson \
  ninja-build \
  pkg-config \
  texinfo \
  wget \
  yasm \
  zlib1g-dev \
  gnutls-bin libunistring-dev \
  openssl libssl-dev \
  nasm libx264-dev libvpx-dev libfdk-aac-dev libmp3lame-dev libopus-dev libavresample-dev libatlas-base-dev \
  libavcodec-dev libatlas3-base libatlas-base-dev libswscale-dev libavresample-dev libavformat-dev


RUN wget https://github.com/Kitware/CMake/releases/download/v3.21.0/cmake-3.21.0.tar.gz && \
    tar xzf cmake-3.21.0.tar.gz && \
    cd cmake-3.21.0 && \
    ./bootstrap && make && make install


# latest は opencv と 相性悪い
# ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2

RUN mkdir -p ~/ffmpeg_sources ~/bin && \
cd ~/ffmpeg_sources && \
wget -O ffmpeg-snapshot.tar.gz https://git.ffmpeg.org/gitweb/ffmpeg.git/snapshot/031c0cb0b4f3cd79e7bc8245db0fdee1239623b3.tar.gz && \
tar xzf ffmpeg-snapshot.tar.gz && \
cd ffmpeg-031c0cb && \
PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
  --prefix="$HOME/ffmpeg_build" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$HOME/ffmpeg_build/include" \
  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
  --extra-libs="-lpthread -lm" \
  --ld="g++" \
  --bindir="$HOME/bin" \
  --enable-gpl \
  --enable-gnutls \
  --enable-libass \
  --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-nonfree \
  --enable-shared --disable-static \
  --enable-shared --disable-static && \
PATH="$HOME/bin:$PATH" make && \
make install && \
hash -r


# build opencv
# RUN mkdir opencv/build && cd opencv/build
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/usr-local-lib.conf \
    && echo "/root/ffmpeg_build/lib/pkgconfig" > /etc/ld.so.conf.d/ffmpeg_pkg_config.conf \
    && echo "/root/ffmpeg_build/lib/" > /etc/ld.so.conf.d/ffmpeg_pkg_lib.conf \
    && cd \
    && git clone -b next https://github.com/opencv/opencv.git \
    && git clone -b next https://github.com/opencv/opencv_contrib.git \
    && export PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig:/root/ffmpeg_build/lib:$PKG_CONFIG_PATH" \
    && mkdir -p ./opencv/build \
    && cd ./opencv/build \
    && cmake -DCMAKE_BUILD_TYPE=RELEASE -DOPENCV_EXTRA_MODULES_PATH=../../opencv_contrib/modules/ -DOPENCV_GENERATE_PKGCONFIG=ON -DWITH_FFMPEG=ON ../ \
    && cmake --build . \
    && make \
    && make install

# add /usr/local/lib/ lddがopencv5を探してくれないので
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/usr-local-lib.conf && ldconfig -v

CMD ["/bin/bash"]
