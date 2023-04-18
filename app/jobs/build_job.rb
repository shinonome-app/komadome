# frozen_string_literal: true

class BuildJob < ActiveJob::Base
  queue_as :default

  def perform
    Rails.logger.info "Starting rake task: build:all_and_rsync"
    system("RAILS_ENV=production bundle exec rake --trace build:all_and_rsync")
    Rails.logger.info "Finished rake task: build:all_and_rsync"
  end
end
