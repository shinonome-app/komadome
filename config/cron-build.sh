#!/bin/bash
set -e

echo "Starting cron build at $(date)"

# Execute rails runner directly to bypass bundle exec
cd /myapp
/usr/local/bin/ruby /myapp/bin/rails runner "
  puts 'Starting build from Rails runner...'
  Rake.application.load_rakefile
  Rake::Task['build:all_and_rsync'].invoke
  puts 'Build completed.'
" RAILS_ENV=production

echo "Build completed at $(date)"