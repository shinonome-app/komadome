#!/bin/bash
set -e

echo "Starting cron build at $(date)"

# Set Bundle-specific environment variables
export GEM_HOME="/usr/local/bundle"
export BUNDLE_APP_CONFIG="/usr/local/bundle"
export BUNDLE_PATH="/usr/local/bundle"

# Import environment variables from the main process
# This includes DATABASE_*, SKYLIGHT_*, MAIN_SITE_URL, etc.
if [ -f /proc/1/environ ]; then
    export $(cat /proc/1/environ | strings | grep -E '^[A-Z_]+=' | grep -v 'PATH=' | grep -v 'RAILS_ENV=' | xargs)
fi

# Change to app directory
cd /myapp

# Execute the build task
bundle exec rails build:all_and_rsync

echo "Build completed at $(date)"