#!/usr/bin/env bash
set -e

EMACS_DIR=".emacs.d"
EMACS_SERVER_DIR="${EMACS_DIR}/server"
EMACS_INIT="${EMACS_DIR}/init.el"

# Ensure directories exist
mkdir -p "${EMACS_SERVER_DIR}"

# When run from make, prefer TTY mode
if [ "$0" = "./scripts/start-emacs.sh" ]; then
    CLIENT_OPTS="-t"
else
    # Otherwise use X11 if display is available
    CLIENT_OPTS="-n -c"
fi

# Start server if not running
if ! pgrep -f "emacs --daemon" > /dev/null; then
    echo "Starting new Emacs server..."
    emacs --daemon --load "$EMACS_INIT" &
    sleep 2
fi

echo "Connecting to Emacs server..."
emacsclient $CLIENT_OPTS || {
    echo "Failed to connect, starting new server..."
    emacs --daemon --load "$EMACS_INIT" &
    sleep 2
    emacsclient $CLIENT_OPTS
}
