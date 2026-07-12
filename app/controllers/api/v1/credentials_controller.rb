module Api::V1
  class CredentialsController < ApiController
    respond_to :html, :xml, :json
    skip_before_action :authenticate_user!, :only=>[:me]
    # `doorkeeper_for :all` was the pre-3.0 Doorkeeper API for gating a whole
    # controller behind a valid token. It no longer exists on the 4.4.3
    # release this app runs (bumped from 1.1.0 in the Rails 5.2 hop, roadmap
    # Task 5) — the modern equivalent is the instance-level
    # `doorkeeper_authorize!` filter. This was silently never caught by the
    # Rails 5.2 hop because classic autoloading never actually loaded this
    # controller class (no test/request exercises `/api/v1/me`), so the
    # `NoMethodError` never fired; Zeitwerk's eager-load-everything semantics
    # (`zeitwerk:check`, and `config.eager_load = true` in production) surface
    # it immediately. Fixing the call is in scope for this hop since it's
    # exactly the kind of previously-dead code Zeitwerk forces to be valid.
    before_action :doorkeeper_authorize!

    #respond_to :json

    def me
      if current_resource_owner
        respond_with current_resource_owner
      else
        error = { :error => "Invalid grant." }
        respond_with error
      end
    end


  end
end

