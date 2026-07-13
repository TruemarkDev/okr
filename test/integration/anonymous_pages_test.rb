require 'test_helper'

# Characterization tests for logged-out page loads. These render the FULL
# layout (application.html.erb / login.html.erb + their sidebar/mobile/tablet
# menu partials), unlike the app's controller tests, which mostly sign a user
# in first — so a `current_user`-without-a-nil-guard bug in a shared layout
# partial, or a stale route-helper name in a Devise view, only ever surfaces
# here, never in a controller test. Pins the fix for both bug classes found by
# manually running the app (see the layouts/_mobile_menu, _tablet_menu,
# _sidebar, and devise/sessions/new diffs in the same commit as this file).
class AnonymousPagesTest < ActionDispatch::IntegrationTest
  test "sign in page renders for a logged-out visitor" do
    get new_user_session_path
    assert_response :success
    assert_select "a[href=?]", user_google_oauth2_omniauth_authorize_path
  end

  test "forgot password page renders for a logged-out visitor" do
    get new_user_password_path
    assert_response :success
  end
end
