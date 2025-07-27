#!/bin/bash
set -e

# Set required environment variables
export PATH=/usr/local/bundle/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export BUNDLE_PATH=/usr/local/bundle
export BUNDLE_APP_CONFIG=/usr/local/bundle
export GEM_HOME=/usr/local/bundle
export RAILS_ENV=production
export RAILS_LOG_LEVEL=warn

# Change to app directory
cd /myapp

# Execute the build task
bundle exec rake build:all_and_rsync