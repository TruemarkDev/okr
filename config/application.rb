require File.expand_path('../boot', __FILE__)

require 'csv'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Fluxday
  class Application < Rails::Application
    # Dual-boot scaffold (see Gemfile / Gemfile.next): this app can boot against
    # either the current Gemfile (Rails 5.2, promoted from Gemfile.next by
    # roadmap Task 5) or Gemfile.next (the next hop target, Rails 6.0 per
    # Task 6) depending on BUNDLE_GEMFILE. Use `NextRails.next?` / `.current?`
    # (from the `next_rails` gem) anywhere config or app code needs to branch
    # between the two during a version hop, e.g.:
    #
    #   if NextRails.next?
    #     # Rails 6.0-only config
    #   else
    #     # Rails 5.2-only config
    #   end
    #
    # No branch was needed for the 4.1 -> 4.2 hop (Task 3) — the `responders`
    # gem (now in this Gemfile) covered the only behavior difference relied on
    # (class-level `respond_to`/`respond_with` in Api::V1::CredentialsController).
    # The 4.2 -> 5.0 hop (Task 4) needed one for `belongs_to_required_by_default`
    # (see below), but that config key exists on every Rails version since, so
    # it no longer needs a NextRails.next? guard. The 5.0 -> 5.2 hop (Task 5)
    # needed no config.rb branch either — every change (gem bumps, controller/
    # test renames, `.uniq` -> `.distinct`, the `current_url` helper fix, the
    # CarrierWave `image_tag(...).url` fixes) worked identically on both
    # Gemfiles once landed. Task 6 (Zeitwerk) is very likely to need a real
    # branch here — Zeitwerk enforces file/constant naming that classic
    # autoloading didn't, so expect `config.autoloader` or eager-load-path
    # differences between the two Gemfiles while that hop is in progress.

    # Rails 5.0 makes `belongs_to` required-by-default. This app was written
    # against the old optional-by-default behavior and has never validated
    # presence on its `belongs_to` associations, so keep that behavior rather
    # than have this hop silently introduce new presence validations across
    # every model. Auditing associations to opt into the new default one at a
    # time is a deliberate future follow-up, not an in-scope side effect of
    # the 4.2 -> 5.0 hop (roadmap Task 4).
    config.active_record.belongs_to_required_by_default = false

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
