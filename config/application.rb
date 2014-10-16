require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Catchups
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Melbourne'
    config.exchange_time_zone_bias = -600

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    def exchange_ws_cli
      @exchange_ws_cli ||= begin
        require 'viewpoint'

        endpoint = ENV['EWS_ENDPOINT'] || raise("Missing EWS_ENDPOINT for connecting to Exchange. Usually in the form of  'https://email.company.com/ews/Exchange.asmx'")
        username = ENV['EWS_USERNAME'] || raise("Missing EWS_USERNAME for connecting to Exchange")
        password = ENV['EWS_PASSWORD'] || raise("Missing EWS_PASSWORD for connecting to Exchange")

        Viewpoint::EWSClient.new endpoint, username, password
      end
    end
  end
end
