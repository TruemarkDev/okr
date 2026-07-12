require File.expand_path('../boot', __FILE__)

require 'csv'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Fluxday
  class Application < Rails::Application
    # Dual-boot scaffold (see Gemfile / Gemfile.next): this app now runs the
    # roadmap's target_stack, Rails 8.0 / Ruby 3.3+ (roadmap Task 9, the LAST
    # version-hop task). `Gemfile.next`/`Gemfile.next.lock` are left in place
    # as the dual-boot mechanism (via `next_rails`'s `NextRails.next?`/
    # `.current?`) but are NOT re-targeted to a further Rails/Ruby hop --
    # there is no next version queued. Task 12 (dual-CI verify + handoff)
    # decides whether to retire the dual-boot CI leg now that the ladder is
    # climbed, or keep the scaffold for whatever comes after 8.0/3.3.
    #
    # History of every `NextRails.next?` branch this app needed during the
    # ladder (all now resolved/removed on promotion — no branch is live here
    # today): Task 3 (4.1->4.2) needed none (`responders` gem covered it).
    # Task 4 (4.2->5.0) branched `belongs_to_required_by_default` briefly;
    # that config key exists on every Rails version since. Task 5 (5.0->5.2)
    # needed no branch at all. Tasks 6/7/8 (5.2->6.0, 6.0->6.1, 6.1->7.0)
    # each branched exactly one `config.load_defaults` bump plus (Task 8) the
    # `require 'redirect_uri_validator'` doorkeeper fix; both removed on each
    # promotion. Task 9 (7.0->7.1->7.2->8.0 + Ruby 3.1->3.3) branched
    # `config.load_defaults` across all three minors during the dual-boot
    # window (Rails 7.0 doesn't understand `load_defaults 7.1`/`7.2`/`8.0` --
    # passing an unknown version raises); now unconditional below.

    # `config.load_defaults 6.0` is what actually turns on Zeitwerk
    # (autoloader defaults to :classic unless a 6.0+ `load_defaults` is set,
    # for backward compat with apps that never opted in). This app never
    # called `load_defaults` at all before this hop (Task 6, roadmap Rails
    # 5.2 -> 6.0). See config/initializers/new_framework_defaults_6_0.rb for
    # the itemized walk of every other flag this bumps and why each one is
    # deliberately left pinned to its pre-6.0 behavior for now.
    #
    # `config.load_defaults 6.1` (Task 7) — see
    # config/initializers/new_framework_defaults_6_1.rb.
    #
    # `config.load_defaults 7.0` (Task 8) — see
    # config/initializers/new_framework_defaults_7_0.rb; only
    # `raise_on_open_redirects` flipped on (audited safe).
    #
    # `config.load_defaults 8.0` (Task 9, roadmap's terminal hop, Rails
    # 7.0 -> 7.1 -> 7.2 -> 8.0 + Ruby 3.1 -> 3.3) now applies unconditionally.
    # See config/initializers/new_framework_defaults_7_1.rb, _7_2.rb, and
    # _8_0.rb for the itemized walk of every individually-togglable behavior
    # change across all three minors -- YJIT (`config.yjit = true`, 7.2) is
    # the only one flipped on; everything else stays pinned to its pre-7.1
    # default, same risk-tiered posture as every prior hop.
    config.load_defaults 8.0

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
