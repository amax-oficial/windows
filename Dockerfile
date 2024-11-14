# Definir el argumento de la versión
ARG VERSION_ARG="4.00"

# Base para la arquitectura amd64
FROM debian:latest AS build-amd64

# Copiar el contenido desde la imagen qemu-docker (si es necesario)
COPY --from=qemux/qemu-docker:6.07 / /

# Redefinir las variables de entorno para los directorios temporales
ENV DEBCONF_NOWARNINGS="yes" \
    DEBIAN_FRONTEND="noninteractive" \
    DEBCONF_NONINTERACTIVE_SEEN="true" \
    TEMP="/home/container/tmp" \
    TMPDIR="/home/container/tmp" \
    APT_LISTS="/home/container/var/lib/apt/lists"

# Crear directorios necesarios y realizar la instalación de paquetes
RUN mkdir -p /home/container/tmp /home/container/var/lib/apt/lists /home/container/var/cache/archives/partial && \
    set -eu && \
    apt-get update -o Dir::State::Lists=$APT_LISTS && \
    apt-get --no-install-recommends -y -o Dir::State::Lists=$APT_LISTS -o Dir::Cache=/home/container/var/cache \
        install bc curl 7zip wsdd samba xz-utils wimtools dos2unix cabextract genisoimage libxml2-utils libarchive-tools && \
    apt-get clean

# Copiar archivos fuente y de assets
COPY ./src /home/container/run/
COPY ./assets /home/container/run/assets

# Añadir archivos adicionales desde URLs externas
ADD https://raw.githubusercontent.com/christgau/wsdd/v0.8/src/wsdd.py /home/container/usr/sbin/wsdd
ADD https://github.com/qemus/virtiso-whql/releases/download/v1.9.43-0/virtio-win-1.9.43.tar.xz /home/container/drivers.txz

# Base para la arquitectura arm64
FROM dockurr/windows-arm:${VERSION_ARG} AS build-arm64

# Selección de la arquitectura de construcción según el target
FROM build-${TARGETARCH}

# Establecer la versión de la imagen en un archivo dentro del contenedor
ARG VERSION_ARG="4.00"
RUN echo "$VERSION_ARG" > /home/container/run/version

# Definir el volumen y los puertos de la aplicación
VOLUME /storage
EXPOSE 8006 3389

# Configuración de variables de entorno adicionales
ENV VERSION="11" \
    RAM_SIZE="4G" \
    CPU_CORES="2" \
    DISK_SIZE="64G"

# Establecer el punto de entrada de la aplicación
ENTRYPOINT ["/home/container/usr/bin/tini", "-s", "/home/container/run/entry.sh"]
