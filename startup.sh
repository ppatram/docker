#!/bin/sh -x

set -eu
echo ${STARTUP_VAR} > startup.var.txt

# do specific startup stuff here"

exec "$@"


