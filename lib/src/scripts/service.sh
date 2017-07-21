#!/usr/bin/env bash
PUB_EXECUTABLE=/usr/lib/dart/bin/pub

NAME=dartmon
PIDFILE=/var/run/dartmon.pid
LOGFILE=/var/log/dartmon.log
DESCRIPTION="Monitor Dart scripts, and run them on startup."
START_SCRIPT=${PUB_EXECUTABLE} global run dartmon start

start() {
    if [ -f ${PIDFILE} ] && kill -0 $(cat ${PIDFILE}); then
        echo 'dartmon already running' >&2
        return 1
    fi
    echo 'Starting dartmon…' >&2
    ${PUB_EXECUTABLE} global run dartmon start &> \"${LOGFILE}\" & echo \$! > "$PIDFILE"
    echo 'dartmon started' >&2
}

stop() {
    if [ ! -f "$PIDFILE" ] || ! kill -0 $(cat "$PIDFILE"); then
        echo 'dartmon is not running' >&2
        return 1
    fi
    echo 'Stopping dartmon…' >&2
    kill -15 $(cat "$PIDFILE") && rm -f "$PIDFILE"
    echo 'dartmon stopped' >&2
}

uninstall() {
    echo -n "Are you really sure you want to uninstall this service? That cannot be undone. [yes|No] "
    local SURE
    read SURE
    if [ "$SURE" = "yes" ]; then
        stop
        ${PUB_EXECUTABLE} global deactivate dartmon
        rm -f "$PIDFILE"
        echo "Notice: log file will not be removed: '$LOGFILE'" >&2
        update-rc.d -f <NAME> remove
        rm -fv "$0"
    fi
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  uninstall)
    uninstall
    ;;
  restart)
    stop
    start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|uninstall}"
esac