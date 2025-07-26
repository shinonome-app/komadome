#!/bin/bash
set -e

# Start cron daemon in background
service cron start

# Execute the main command
exec "$@"