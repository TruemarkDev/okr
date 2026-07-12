# Ported from Doorkeeper's own `add_client_confidentiality` generator
# (the CVE-2018-1000211 fix), pulled forward as part of the roadmap Task 8
# doorkeeper 4.4.3 -> 5.1.x bump (see the Gemfile comment) -- 5.x's
# `Doorkeeper::Application` model hard-validates
# `validates :confidential, inclusion: { in: [true, false] }`, so the
# column has to exist before that model can be instantiated/loaded at all.
# `default: true` matches Doorkeeper's own migration template (maintains
# backwards compatibility: existing applications keep requiring a secret).
class AddConfidentialToOauthApplications < ActiveRecord::Migration[6.1]
  def change
    add_column :oauth_applications, :confidential, :boolean, null: false, default: true
  end
end
