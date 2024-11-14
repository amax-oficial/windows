ARG VERSION_ARG="4.00"

# Construcción para la arquitectura amd64
FROM scratch AS build-amd64
COPY --from=qemux/qemu-docker:6.07 / /

# Redefinimos variables de entorno para que los directorios temporales apunten a /home/container
ENV DEBCONF_NOWARNINGS="yes" \
    DEBIAN_FRONTEND="noninteractive" \
    DEBCONF_NONINTERACTIVE_SEEN="true" \
    TEMP="/home/container/tmp" \
    TMPDIR="/home/container/tmp" \
    APT_LISTS="/home/container/var/lib/apt/lists"

RUN mkdir -p /home/container/tmp /home/container/var/lib/apt/lists && \
    set -eu && \
    apt-get update -o Dir::State::Lists=$APT_LISTS && \
    apt-get --no-install-recommends -y -o Dir::State::Lists=$APT_LISTS -o Dir::Cache=/home/container/var/cache \
        install bc curl 7zip wsdd samba xz-utils wimtools dos2unix cabextract genisoimage libxml2-utils libarchive-tools && \
    apt-get clean

# Copiamos archivos y configuraciones en /home/container
COPY ./src /home/container/run/
COPY ./assets /home/container/run/assets

# Añadimos archivos adicionales
ADD https://raw.githubusercontent.com/christgau/wsdd/v0.8/src/wsdd.py /home/container/usr/sbin/wsdd
ADD https://github.com/qemus/virtiso-whql/releases/download/v1.9.43-0/virtio-win-1.9.43.tar.xz /home/container/drivers.txz

# Construcción para la arquitectura arm64
FROM dockurr/windows-arm:${VERSION_ARG} AS build-arm64
FROM build-${TARGETARCH}

ARG VERSION_ARG="4.00"
RUN echo "$VERSION_ARG" > /home/container/run/version

# Definimos el volumen y puertos de la aplicación
VOLUME /storage
EXPOSE 8006 3389

# Configuramos variables de entorno adicionales
ENV VERSION="11" \
    RAM_SIZE="4G" \
    CPU_CORES="2" \
    DISK_SIZE="64G"

# Establecemos el punto de entrada de la aplicación
ENTRYPOINT ["/home/container/usr/bin/tini", "-s", "/home/container/run/entry.sh"]
