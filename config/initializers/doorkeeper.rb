# Task 8 (Rails 6.1 -> 7.0) fix: `Doorkeeper.configure` below synchronously
# requires Doorkeeper's AR models (`Doorkeeper::Application`/`AccessGrant`/
# `AccessToken`), which reference `RedirectUriValidator` -- a class Doorkeeper
# ships under its own `app/validators` (an ordinary, *reloadable* autoload
# path/eager_load_path contributed by its Engine), never `require`d directly
# anywhere in the gem itself. Through Rails 6.1, a legacy
# `ActiveSupport::Dependencies` const_missing bridge still resolved reloadable
# autoload paths during initializers (with a deprecation warning); Rails 7.0
# removed that bridge outright (per Zeitwerk's own author, on the upstream
# doorkeeper issue for this exact problem: "in Rails 7 you just cannot
# autoload reloadable code during initialization"). Marking Doorkeeper's
# `app/validators` as an `autoload_once_paths` entry in
# `config/application.rb` was tried first, but Zeitwerk raises
# `raise_if_conflicting_directory` because Rails::Engine's default `paths.add
# "app", eager_load: true, glob: "{*,*/concerns}"` already sweeps that same
# directory into the *main* (reloadable) autoloader -- a directory can't be
# managed by two loaders at once, and surgically excluding just
# `app/validators` from the engine's glob isn't exposed as public API. The
# doorkeeper maintainers' own documented short-term fix for this exact issue
# (doorkeeper-gem/doorkeeper#1275) is simpler: `require` the file directly.
# Since `app/validators` is on `$LOAD_PATH` (Rails'
# `config.add_autoload_paths_to_load_path`, still true here), a plain
# `require` resolves it without needing the gem's absolute path. Only needed
# once Rails 7.0's stricter Zeitwerk-only autoloading applies (this
# initializer worked as-is under Rails 6.1, just with a deprecation warning).
# Unconditional now that Gemfile.next has been promoted to become this
# Gemfile (both Gemfile and the new Gemfile.next run Rails 7.0+).
require 'redirect_uri_validator'

Doorkeeper.configure do
  # Change the ORM that doorkeeper will use.
  # Currently supported options are :active_record, :mongoid2, :mongoid3, :mongo_mapper
  orm :active_record

  # This block will be called to check whether the resource owner is authenticated or not.
  resource_owner_authenticator do
    current_user || warden.authenticate!(:scope => :user)
    #raise "Please configure doorkeeper resource_owner_authenticator block located in #{__FILE__}"
    # Put your resource owner authentication logic here.
    # Example implementation:
    #   User.find_by_id(session[:user_id]) || redirect_to(new_user_session_url)
  end

  # If you want to restrict access to the web interface for adding oauth authorized applications, you need to declare the block below.
  admin_authenticator do
  #   # Put your admin authentication logic here.
  #   # Example implementation:
    user = current_user || warden.authenticate!(:scope => :user)
    #user.role.downcase == "manager"
    user.role.downcase == "manager" ? true : redirect_to(root_url,:notice=>'Access denied')
  #   Admin.find_by_id(session[:admin_id]) || redirect_to(new_admin_session_url)
  end

  # Authorization Code expiration time (default 10 minutes).
  # authorization_code_expires_in 10.minutes

  # Access token expiration time (default 2 hours).
  # If you want to disable expiration, set this to nil.
  # access_token_expires_in 2.hours

  # Issue access tokens with refresh token (disabled by default)
  # use_refresh_token

  # Provide support for an owner to be assigned to each registered application (disabled by default)
  # Optional parameter :confirmation => true (default false) if you want to enforce ownership of
  # a registered application
  # Note: you must also run the rails g doorkeeper:application_owner generator to provide the necessary support
  # enable_application_owner :confirmation => false

  # Define access token scopes for your provider
  # For more information go to https://github.com/applicake/doorkeeper/wiki/Using-Scopes
  # default_scopes  :public
  # optional_scopes :write, :update

  # Change the way client credentials are retrieved from the request object.
  # By default it retrieves first from the `HTTP_AUTHORIZATION` header, then
  # falls back to the `:client_id` and `:client_secret` params from the `params` object.
  # Check out the wiki for more information on customization
  # client_credentials :from_basic, :from_params

  # Change the way access token is authenticated from the request object.
  # By default it retrieves first from the `HTTP_AUTHORIZATION` header, then
  # falls back to the `:access_token` or `:bearer_token` params from the `params` object.
  # Check out the wiki for more information on customization
  # access_token_methods :from_bearer_authorization, :from_access_token_param, :from_bearer_param

  # Change the test redirect uri for client apps
  # When clients register with the following redirect uri, they won't be redirected to any server and the authorization code will be displayed within the provider
  # The value can be any string. Use nil to disable this feature. When disabled, clients must provide a valid URL
  # (Similar behaviour: https://developers.google.com/accounts/docs/OAuth2InstalledApp#choosingredirecturi)
  #
  # test_redirect_uri 'urn:ietf:wg:oauth:2.0:oob'

  # Under some circumstances you might want to have applications auto-approved,
  # so that the user skips the authorization step.
  # For example if dealing with trusted a application.
  # skip_authorization do |resource_owner, client|
  #   client.superapp? or resource_owner.admin?
  # end

  # WWW-Authenticate Realm (default "Doorkeeper").
  # realm "Doorkeeper"

  # Allow dynamic query parameters (disabled by default)
  # Some applications require dynamic query parameters on their request_uri
  # set to true if you want this to be allowed
  # wildcard_redirect_uri false
end
