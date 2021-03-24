FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV PLATFORMIO_CORE_DIR=/.platformio

RUN mkdir /app
WORKDIR /app

COPY dummy-esp32 /opt/dummy-esp32
COPY dummy-esp32-idf /opt/dummy-esp32-idf

RUN apt-get update -qq && \
    apt-get install -y -qq software-properties-common && \
    apt-add-repository universe && \
    apt-get update -qq && \
    apt-get install -qq -y --no-install-recommends \
      bc \
      bison \
      build-essential \
      curl \
      flex \
      gcc \
      git \
      gperf \
      jq \
      libncurses-dev \
      make \
      python3-dev \
      python3-pip \
      srecord \
      unzip \
      wget \
      xz-utils

RUN python3 -m pip install --upgrade pip setuptools
RUN python3 -m pip install platformio

RUN python3 -V

# ESP32 Arduino Frameworks for Platformio
RUN pio platform install espressif32 && \
    cat /.platformio/platforms/espressif32/platform.py && \
    chmod 777 /.platformio/platforms/espressif32/platform.py && \
    sed -i 's/~2/>=1/g' /.platformio/platforms/espressif32/platform.py && \
    cat /.platformio/platforms/espressif32/platform.py

# ESP-IDF for projects containing `sdkconfig` or `*platform*espidf*` in platformio.ini
# https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started-legacy/linux-setup.html
RUN mkdir -p /esp && \
    cd /esp && \
    wget https://dl.espressif.com/dl/xtensa-esp32-elf-gcc8_4_0-esp-2020r3-linux-amd64.tar.gz && \
    tar -xzf ./xtensa-*.tar.gz && \
    echo "export PATH=$PATH:/esp/xtensa-esp32-elf/bin" > .profile && \
    echo "export IDF_PATH=/esp/esp-idf" > .profile && \
    git clone https://github.com/espressif/esp-idf.git --recurse-submodules

# Build tests
RUN export PATH=$PATH:/esp/xtensa-esp32-elf/bin && \
    export IDF_PATH=/esp/esp-idf && \
    python3 -m pip install -r /esp/esp-idf/requirements.txt

RUN export PATH=$PATH:/esp/xtensa-esp32-elf/bin && \
    export IDF_PATH=/esp/esp-idf && \
    cd /esp/esp-idf/examples/get-started/hello_world && \
    cp -v /opt/dummy-esp32-idf/sdkconfig . && \
    ls -la && \
    ln -s $(which python3) /usr/bin/python && \
    make

WORKDIR /opt/dummy-esp32
RUN pio --version && pio run && pio check
RUN rm -rf /.platformio/packages/framework-arduinoespressif32/.gitmodules

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /src && \
    chmod -R 777 /.platformio && \
    chmod -R 777 /esp
WORKDIR /src
ENTRYPOINT ["platformio"]
