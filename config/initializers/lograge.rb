Rails.application.configure do
  config.lograge.enabled = true

  config.lograge.formatter = Lograge::Formatters::Json.new
  config.colorize_logging = false
  config.lograge.logger = ActiveSupport::Logger.new(Rails.root.join('log', "#{Rails.env}.log"))
  config.lograge.custom_options = lambda do |event|
    { :ddsource => 'ruby',
      :params => event.payload[:params].reject { |k| %w(controller action).include? k }
    }
  end

  config.lograge.ignore_actions = ['HealthController#show']
end