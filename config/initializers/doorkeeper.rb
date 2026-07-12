# Task 8 (Rails 6.1 -> 7.0) fix, revised in Task 9: `Doorkeeper.configure`
# below synchronously requires Doorkeeper's AR models
# (`Doorkeeper::Application`/`AccessGrant`/`AccessToken`), which reference
# `RedirectUriValidator` -- a class Doorkeeper ships under its own
# `app/validators` (an ordinary, *reloadable* autoload path/eager_load_path
# contributed by its Engine), never `require`d directly anywhere in the gem
# itself. Through Rails 6.1, a legacy `ActiveSupport::Dependencies`
# const_missing bridge still resolved reloadable autoload paths during
# initializers (with a deprecation warning); Rails 7.0 removed that bridge
# outright (per Zeitwerk's own author, on the upstream doorkeeper issue for
# this exact problem: "in Rails 7 you just cannot autoload reloadable code
# during initialization").
#
# Task 8 originally fixed this with a bare `require 'redirect_uri_validator'`,
# relying on Doorkeeper's `app/validators` being on `$LOAD_PATH` via Rails'
# `config.add_autoload_paths_to_load_path`. That stopped resolving under this
# hop's Rails 8.0 (`LoadError: cannot load such file -- redirect_uri_validator`)
# -- `add_autoload_paths_to_load_path`'s effective value shifted somewhere in
# the 7.1/7.2/8.0 span even though this app's own new_framework_defaults
# templates left it commented/unset. Rather than chase which exact minor
# flipped it (and re-break on some future Rails version that changes it
# again), require the file by Doorkeeper's own gem-root path instead --
# doesn't depend on `$LOAD_PATH` configuration at all.
require Doorkeeper::Engine.root.join('app', 'validators', 'redirect_uri_validator')

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

  # roadmap Task 10 (doorkeeper 5.x modernization surface, deliberately left
  # off during Task 8/9's forced 4.4.3 -> 5.1.2 bump to keep those hops
  # minimal): hash access/refresh tokens and application secrets at rest
  # instead of storing them in plaintext. This is transparent to every OAuth
  # client (fluxday's own `Api::V1::CredentialsController`/omniauth-fluxapp
  # integration and any registered `OauthApplication`) -- hashing happens in
  # the same `oauth_applications`/`oauth_access_tokens`/`oauth_access_grants`
  # string columns via Doorkeeper's own SHA256 SecretStoring/Hashing
  # strategies, no schema migration required (confirmed against
  # doorkeeper-5.1.2's `lib/doorkeeper/secret_storing/*`). `reuse_access_token`
  # is not enabled here (and can't be combined with `hash_token_secrets`
  # anyway), so this doesn't interact with it.
  #
  # A plaintext fallback is required alongside this: fluxday already has real
  # `oauth_applications` rows (and any live access/refresh tokens) with
  # plaintext secrets persisted before this change. Without it, every
  # existing client secret and outstanding token would stop validating the
  # moment this deploys. New applications/tokens issued after this change are
  # hashed going in; existing plaintext rows keep working via `fallback:
  # :plain` and are transparently upgraded to hashed values the next time
  # their secret is rotated/token is reissued.
  #
  # Note: doorkeeper 5.1.2's `hash_token_secrets`/`hash_application_secrets`
  # take the fallback as a keyword argument here -- the standalone
  # `fallback_to_plain_secrets` directive doesn't exist until a later 5.x
  # release, so it can't be used on this pinned version.
  hash_token_secrets fallback: :plain
  hash_application_secrets fallback: :plain

  # roadmap Task 10: the rest of doorkeeper 5.x's modernization surface was
  # assessed and deliberately left off/default -- no concrete need found in
  # fluxday's actual usage (itself an OAuth2 *provider* for internally
  # registered `OauthApplication`/`Api::V1::CredentialsController` clients,
  # and separately an OAuth2 *client* of an external fluxapp via
  # omniauth-fluxapp/omniauth-oauth2 -- neither is a public/mobile client,
  # and only one grant flow is actually exercised):
  #
  # - PKCE: not adopted. PKCE exists to protect public clients that can't
  #   hold a secret (native/mobile/SPA). Every registered `OauthApplication`
  #   here is a confidential, server-registered client (see the
  #   `confidential` column default below) -- no public client exists to
  #   protect.
  # - previous_refresh_token: not adopted. `use_refresh_token` itself is
  #   still commented out/disabled above (unchanged from Task 8/9) -- there
  #   is no refresh-token flow in play at all, so rotation-without-
  #   invalidation has nothing to apply to.
  # - scopes_by_grant_type: not adopted. This app defines no
  #   default_scopes/optional_scopes (both still commented out below) and
  #   doesn't customize `grant_flows`, so there's only the doorkeeper
  #   default flow set with no per-grant-type scope distinction to make.
  #
  # If any of the above becomes true (a public client is registered, refresh
  # tokens get turned on, or multiple grant types with different scope needs
  # appear), revisit this list -- don't adopt any of them speculatively.

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
