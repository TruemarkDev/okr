require 'test_helper'

# Characterization tests for the OAuth login entry points
# (`Users::OmniauthCallbacksController#google_oauth2` and `#fluxapp`).
#
# These sit next to the Doorkeeper surface in the auth stack and are pinned so
# the Doorkeeper 1.1 -> 5.x migration (and any auth refactor) has a regression
# net on the *login* side, not just the API side. The OmniAuth middleware is
# bypassed here — we set `request.env["omniauth.auth"]` directly and invoke the
# callback action, which is how Devise's own OmniAuth tests exercise callbacks.
#
# Current behavior pinned:
#   * known email  -> user signed in, flash notice, redirect to the signed-in root.
#   * unknown email -> redirect to the sign-in page with an alert, nobody signed in.
# Both providers currently resolve the user purely by *email*:
#   google_oauth2 via User.find_for_google_oauth2 (which ignores uid, matches email),
#   fluxapp       via User.find_by_email(auth.info.email).
class Users::OmniauthCallbacksControllerTest < ActionController::TestCase
  tests Users::OmniauthCallbacksController

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  def auth_hash(provider:, email:, uid: '000')
    OmniAuth::AuthHash.new(
      provider: provider,
      uid: uid,
      info: { email: email, name: 'Some One', nickname: 'someone' }
    )
  end

  # --- google_oauth2 -------------------------------------------------------

  test "google_oauth2 with a known email signs the user in and redirects" do
    @request.env["omniauth.auth"] = auth_hash(provider: 'google_oauth2', email: users(:admin).email)

    get :google_oauth2

    assert_response :redirect
    assert_not_nil flash[:notice]
    assert_equal users(:admin), assigns(:user)
    assert warden.authenticated?(:user)
  end

  test "google_oauth2 with an unknown email redirects to sign-in with an alert" do
    @request.env["omniauth.auth"] = auth_hash(provider: 'google_oauth2', email: 'nobody@nowhere.example')

    get :google_oauth2

    assert_redirected_to new_user_session_path
    assert_not_nil flash[:alert]
    assert_not warden.authenticated?(:user)
  end

  # --- fluxapp -------------------------------------------------------------

  test "fluxapp with a known email signs the user in and redirects" do
    @request.env["omniauth.auth"] = auth_hash(provider: 'fluxapp', email: users(:admin).email)

    get :fluxapp

    assert_response :redirect
    assert_not_nil flash[:notice]
    assert_equal users(:admin), assigns(:user)
    assert warden.authenticated?(:user)
  end

  test "fluxapp with an unknown email redirects to sign-in with an alert" do
    @request.env["omniauth.auth"] = auth_hash(provider: 'fluxapp', email: 'nobody@nowhere.example')

    get :fluxapp

    assert_redirected_to new_user_session_path
    assert_not_nil flash[:alert]
    assert_not warden.authenticated?(:user)
  end
end
