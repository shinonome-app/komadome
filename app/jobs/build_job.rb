# frozen_string_literal: true

class BuildJob < ActiveJob::Base
  queue_as :default

  def perform
    Rails.logger.info "Starting rake task: build:all_and_rsync"
    system("bundle exec rake build:all_and_rsync")
    Rails.logger.info "Finished rake task: build:all_and_rsync"
  end
end
