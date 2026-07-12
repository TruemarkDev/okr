# Ported from Doorkeeper's own `add_client_confidentiality` generator
# (the CVE-2018-1000211 fix), pulled forward as part of the roadmap Task 8
# doorkeeper 4.4.3 -> 5.1.x bump (see the Gemfile comment) -- 5.x's
# `Doorkeeper::Application` model hard-validates
# `validates :confidential, inclusion: { in: [true, false] }`, so the
# column has to exist before that model can be instantiated/loaded at all.
# `default: true` matches Doorkeeper's own migration template (maintains
# backwards compatibility: existing applications keep requiring a secret).
#
# Re-audited as part of roadmap Task 10 (doorkeeper 5.x modernization
# surface): every `OauthApplication` in this app is registered through the
# admin-only `OauthApplicationsController`/`Doorkeeper::Application` web UI
# (see `admin_authenticator` in config/initializers/doorkeeper.rb, gated to
# managers/admins) for server-to-server integrations -- there is no
# public/mobile/SPA client anywhere in the codebase (`app/controllers/api/v1`
# is a token-authenticated API for those same registered confidential
# clients, not a public-client flow). `default: true` for every existing and
# future row is correct; nothing here should be `confidential: false`.
class AddConfidentialToOauthApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :oauth_applications, :confidential, :boolean, null: false, default: true
  end
end
