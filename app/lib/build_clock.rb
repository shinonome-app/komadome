# frozen_string_literal: true

require 'active_support/testing/time_helpers'

# Pins "today" for a static build so output is reproducible.
#
# Freezing the clock once at the build entry point covers them all,
# rather than threading a date through every call site.
#
# This mirrors komadome-rs's `--date` / KOMADOME_BUILD_DATE flag.
# See komadome-rs/docs/parity.md.
#
# Usage:
#   BuildClock.with_pinned_date { Rake::Task['build:generate'].invoke }
#
# When KOMADOME_BUILD_DATE is unset/blank the block runs against the real clock.
module BuildClock
  ENV_KEY = 'KOMADOME_BUILD_DATE'

  extend ActiveSupport::Testing::TimeHelpers

  module_function

  def with_pinned_date(&)
    raw = ENV[ENV_KEY].to_s.strip
    return yield if raw.empty?

    instant = Time.zone.parse(raw)
    raise ArgumentError, "invalid #{ENV_KEY}=#{raw.inspect} (expected YYYY-MM-DD)" if instant.nil?

    travel_to(instant, &)
  end
end
