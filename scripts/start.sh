#!/bin/bash
echo "---Ensuring UID: ${UID} matches user---"
usermod -u ${UID} ${USER}
echo "---Ensuring GID: ${GID} matches user---"
groupmod -g ${GID} ${USER} > /dev/null 2>&1 ||:
usermod -g ${GID} ${USER}
echo "---Setting umask to ${UMASK}---"
umask ${UMASK}

echo "---Checking for optional scripts---"
cp -f /opt/custom/user.sh /opt/scripts/start-user.sh > /dev/null 2>&1 ||:
cp -f /opt/scripts/user.sh /opt/scripts/start-user.sh > /dev/null 2>&1 ||:

if [ -f /opt/scripts/start-user.sh ]; then
    echo "---Found optional script, executing---"
    chmod -f +x /opt/scripts/start-user.sh ||:
    /opt/scripts/start-user.sh || echo "---Optional Script has thrown an Error---"
else
    echo "---No optional script found, continuing---"
fi

echo "---Taking ownership of data...---"
chown -R root:${GID} /opt/scripts
chmod -R 750 /opt/scripts
chown -R ${UID}:${GID} ${DATA_DIR}
chown -R root:${GID} ${SCRIPTS_DIR}
chmod -R 750 ${SCRIPTS_DIR}
chown -R ${UID}:${GID} ${SCRIPTS_DIR}
 
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

# Start term handler (foreground)
run_as_user "${SCRIPTS_DIR}/term_handler.sh"

echo "---Checking for copy_configs.sh---"
if [ -f ${SCRIPTS_DIR}/copy_configs.sh ]; then
  echo "---Found script Copying Configs---"
  if error_output=$(run_as_user ${SCRIPTS_DIR}/copy_configs.sh 2>&1); then
    echo "---Data copied---"
  else
    echo "---Error copying configs: $error_output"
  fi
fi

# Start main server script in background
run_as_user /opt/scripts/start-server.sh &
killpid="$!"
while true
do
	wait $killpid
	exit 0;
done
