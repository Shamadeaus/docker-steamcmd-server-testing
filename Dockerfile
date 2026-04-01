FROM ich777/debian-baseimage:bullseye_amd64

LABEL org.opencontainers.image.authors="admin@minenet.at"
LABEL org.opencontainers.image.source="https://github.com/ich777/docker-steamcmd-server"

RUN apt-get update && \
    apt-get -y install --no-install-recommends lib32gcc-s1 lib32stdc++6 lib32z1 util-linux gosu && \
    rm -rf /var/lib/apt/lists/*

ENV DATA_DIR="/serverdata"
ENV STEAMCMD_DIR="${DATA_DIR}/steamcmd"
ENV SERVER_DIR="${DATA_DIR}/serverfiles"
ENV SCRIPTS_DIR="${DATA_DIR}/scripts"
ENV GAME_ID="template"
ENV GAME_NAME="template"
ENV GAME_PARAMS="template"
ENV GAME_PORT=27015
ENV VALIDATE=""
ENV UMASK=000
ENV UID=99
ENV GID=100
ENV USERNAME=""
ENV PASSWRD=""
ENV USER="steam"
ENV DATA_PERM=770

RUN mkdir $DATA_DIR && \
	mkdir $STEAMCMD_DIR && \
	mkdir $SERVER_DIR && \
	mkdir $SCRIPTS_DIR && \
	useradd -d $DATA_DIR -s /bin/bash $USER && \
	chown -R $USER $DATA_DIR && \
	ulimit -n 2048

COPY scripts/ /opt/scripts/
# Normalize possible CRLF line endings from host and ensure scripts are executable
RUN sed -i 's/\r$//' /opt/scripts/*.sh || true && \
	chmod -R 750 /opt/scripts/

#Server Start
ENTRYPOINT ["/opt/scripts/start.sh"]
