#!/bin/bash
if [ ! -f ${STEAMCMD_DIR}/steamcmd.sh ]; then
    echo "SteamCMD not found!"
    wget -q -O ${STEAMCMD_DIR}/steamcmd_linux.tar.gz http://media.steampowered.com/client/steamcmd_linux.tar.gz 
    tar --directory ${STEAMCMD_DIR} -xvzf /serverdata/steamcmd/steamcmd_linux.tar.gz
    rm ${STEAMCMD_DIR}/steamcmd_linux.tar.gz
fi

echo "---Update SteamCMD---"
if [ "${USERNAME}" == "" ]; then
    ${STEAMCMD_DIR}/steamcmd.sh \
    +login anonymous \
    +quit
else
    ${STEAMCMD_DIR}/steamcmd.sh \
    +login ${USERNAME} ${PASSWRD} \
    +quit
fi

echo "---Update Server---"
if [ "${USERNAME}" == "" ]; then
    if [ "${VALIDATE}" == "true" ]; then
    	echo "---Validating installation---"
        ${STEAMCMD_DIR}/steamcmd.sh \
        +force_install_dir ${SERVER_DIR} \
        +login anonymous \
        +app_update ${GAME_ID} validate \
        +quit
    else
        ${STEAMCMD_DIR}/steamcmd.sh \
        +force_install_dir ${SERVER_DIR} \
        +login anonymous \
        +app_update ${GAME_ID} \
        +quit
    fi
else
    if [ "${VALIDATE}" == "true" ]; then
    	echo "---Validating installation---"
        ${STEAMCMD_DIR}/steamcmd.sh \
        +force_install_dir ${SERVER_DIR} \
        +login ${USERNAME} ${PASSWRD} \
        +app_update ${GAME_ID} validate \
        +quit
    else
        ${STEAMCMD_DIR}/steamcmd.sh \
        +force_install_dir ${SERVER_DIR} \
        +login ${USERNAME} ${PASSWRD} \
        +app_update ${GAME_ID} \
        +quit
    fi
fi

echo "---Prepare Server---"
# Helper: run a script as the configured non-root user when process is root,
# otherwise execute directly (Unraid runs containers as non-root by default).
run_as_user() {
    target="$1"
    shift || true
    if [ "$(id -u)" -eq 0 ]; then
        if command -v gosu >/dev/null 2>&1; then
            gosu "${USER}" "$target" "$@"
        else
            runuser -u "${USER}" -- "$target" "$@"
        fi
    else
        if [ -x "$target" ]; then
            "$target" "$@"
        else
            /bin/bash "$target" "$@"
        fi
    fi
}

if error_output=$(run_as_user "${SCRIPTS_DIR}/prepare_server.sh" 2>&1); then
  echo "---Prepare server completed---"
else
  echo "---Error preparing server: $error_output"
fi

if error_output=$(chmod -R ${DATA_PERM} ${DATA_DIR} 2>&1); then
  echo "---Permissions set---"
else
  echo "---Error setting permissions: $error_output"
fi
echo "---Server ready---"

echo "---Start Server---"
run_as_user "${SCRIPTS_DIR}/start_server.sh"
