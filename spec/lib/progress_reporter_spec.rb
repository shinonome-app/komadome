# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProgressReporter do
  let(:reporter) { ProgressReporter.new(verbose: false) } # Disable output for tests

  describe '#initialize' do
    it 'initializes with default stats' do
      expect(reporter.stats).to eq({ success: 0, failed: 0, errors: [] })
    end
  end

  describe '#reset_stats' do
    it 'resets statistics to initial state' do
      reporter.record_success
      reporter.record_failure('error')

      reporter.reset_stats

      expect(reporter.stats).to eq({ success: 0, failed: 0, errors: [] })
    end
  end

  describe '#record_success' do
    it 'increments success count' do
      reporter.record_success
      reporter.record_success

      expect(reporter.stats[:success]).to eq(2)
    end
  end

  describe '#record_failure' do
    it 'increments failure count and stores error message' do
      reporter.record_failure('Error 1')
      reporter.record_failure('Error 2')

      expect(reporter.stats[:failed]).to eq(2)
      expect(reporter.stats[:errors]).to eq(['Error 1', 'Error 2'])
    end
  end

  describe '#show_progress' do
    it 'calculates correct progress statistics' do
      start_time = Time.current - 10 # 10 seconds ago

      # Should not raise any errors
      expect { reporter.show_progress(50, 100, start_time) }.not_to raise_error
    end
  end

  describe 'thread safety' do
    it 'handles concurrent access safely' do
      threads = []

      10.times do
        threads << Thread.new do
          10.times do
            reporter.record_success
            reporter.record_failure('concurrent error')
          end
        end
      end

      threads.each(&:join)

      expect(reporter.stats[:success]).to eq(100)
      expect(reporter.stats[:failed]).to eq(100)
      expect(reporter.stats[:errors].size).to eq(100)
    end
  end
end
