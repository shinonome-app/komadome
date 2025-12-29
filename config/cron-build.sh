#!/bin/bash
set -e

echo "Starting cron build at $(date)"

# Set Bundle-specific environment variables
export GEM_HOME="/usr/local/bundle"
export BUNDLE_APP_CONFIG="/usr/local/bundle"
export BUNDLE_PATH="/usr/local/bundle"

# Import environment variables from the main process
# This includes DATABASE_*, SKYLIGHT_*, MAIN_SITE_URL, etc.
# Using tr instead of strings to handle binary null separators properly
if [ -f /proc/1/environ ]; then
    while IFS='=' read -r -d '' key value; do
        # Skip PATH and RAILS_ENV (we set these ourselves)
        if [[ "$key" != "PATH" && "$key" != "RAILS_ENV" && "$key" =~ ^[A-Z_]+$ ]]; then
            export "$key=$value"
        fi
    done < /proc/1/environ
fi

# Change to app directory
cd /myapp

# Execute the build task
bundle exec rails build:all_and_rsync

echo "Build completed at $(date)"