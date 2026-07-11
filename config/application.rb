require File.expand_path('../boot', __FILE__)

require 'csv'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Fluxday
  class Application < Rails::Application
    # Dual-boot scaffold (see Gemfile / Gemfile.next): this app can boot against
    # either the current Gemfile (Rails 4.1) or Gemfile.next (the next hop
    # target) depending on BUNDLE_GEMFILE. Use `NextRails.next?` / `.current?`
    # (from the `next_rails` gem) anywhere config or app code needs to branch
    # between the two during a version hop, e.g.:
    #
    #   if NextRails.next?
    #     # Rails 4.2-only config
    #   else
    #     # Rails 4.1-only config
    #   end
    #
    # No branch is needed yet for the 4.1 -> 4.2 hop (Task 3) — the `responders`
    # gem in Gemfile.next covers the only behavior difference we rely on
    # (class-level `respond_to`/`respond_with` in Api::V1::CredentialsController).

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.to_prepare do
      # Base layout. Uses app/views/layouts/my_layout.html.erb
      #Doorkeeper::ApplicationController.layout "my_layout"

      # Only Applications list
      #Doorkeeper::ApplicationsController.layout "my_layout"

      # Only Authorization endpoint
      Doorkeeper::AuthorizationsController.layout "doorkeeper"

      # Only Authorized Applications
      Doorkeeper::AuthorizedApplicationsController.layout "doorkeeper"
    end
  end
end
