require 'test_helper'

# Characterization tests for the Doorkeeper-gated API surface
# (`Api::V1::CredentialsController#me` + `Api::V1::ApiController#current_resource_owner`).
#
# These PIN CURRENT BEHAVIOR (bugs included) so the planned Doorkeeper 1.1 -> 5.x
# migration (roadmap Task 10) has a real regression net. **As of this checkout the
# entire `/api/v1/me` endpoint returns HTTP 500 in every code path** — this suite
# encodes exactly which layer breaks in each case, so the migration that fixes them
# is forced to consciously update these expectations:
#
#   * missing / invalid token  -> doorkeeper-5.1.2's `doorkeeper_render_error`
#     raises `ArgumentError (given 2, expected 0..1)` under Rails 8 BEFORE any
#     response is produced. The reject path is broken, not merely un-pretty.
#     >> The migration must turn this into a clean 401.
#   * valid token, owner linked -> doorkeeper authorizes and `current_resource_owner`
#     resolves the user (good), but serializing that user to JSON hits
#     `ImageUploader#default_url -> asset_path("fallback/user.png")`, and only
#     *versioned* fallbacks exist (`icon_user.png`, `thumbnail_user.png`, ...),
#     so it raises `Sprockets::Rails::Helper::AssetNotFound`. That this raises
#     AssetNotFound (and not the doorkeeper ArgumentError or the "Invalid grant"
#     branch) is itself the proof that the token authorized and the owner resolved.
#     >> The migration must make the success path return 200 with the owner.
#   * valid token, owner NOT linked to the app -> `current_resource_owner` is nil and
#     the `else` branch renders `{ error: "Invalid grant." }`. This is the one path
#     that does NOT 500 today; pinned as the working baseline.
#
# `#me` runs `skip_before_action :authenticate_user!`, so the only gate under test
# here is Doorkeeper's, not Devise's.
class Api::V1::CredentialsControllerTest < ActionController::TestCase
  tests Api::V1::CredentialsController

  setup do
    @app = OauthApplication.create!(
      name: 'API Consumer',
      redirect_uri: 'https://example.com/callback',
      uid: "uid-#{SecureRandom.hex(6)}",
      secret: "secret-#{SecureRandom.hex(6)}"
    )
    @user = users(:admin)
    # current_resource_owner resolves the owner *through the application's users*
    # association (user_oauth_applications join), so the link must exist.
    UserOauthApplication.create!(user: @user, oauth_application: @app)
  end

  def access_token_for(resource_owner_id:, application_id:)
    Doorkeeper::AccessToken.create!(
      resource_owner_id: resource_owner_id,
      application_id: application_id,
      scopes: ''
    )
  end

  def authorize_with(token)
    @request.headers['Authorization'] = "Bearer #{token.token}"
  end

  # --- reject path (the Doorkeeper gate itself) ----------------------------
  # BUG PINNED: doorkeeper-5.1.2 error rendering is incompatible with Rails 8;
  # the reject path raises instead of returning 401. The exact class is
  # incidental — the load-bearing fact is that a request WITHOUT a valid token
  # never produces a successful response and never reaches the action body.

  test "missing token: reject path currently raises (must become 401 post-migration)" do
    assert_raises(ArgumentError) do
      get :me, format: :json
    end
  end

  test "invalid token: reject path currently raises (must become 401 post-migration)" do
    @request.headers['Authorization'] = 'Bearer not-a-real-token'

    assert_raises(ArgumentError) do
      get :me, format: :json
    end
  end

  # --- success path (authorized, owner resolved) ---------------------------
  # The AssetNotFound raise proves authorization succeeded and the owner
  # resolved (we got all the way to JSON serialization of that user).

  test "valid token, linked owner: authorizes and resolves owner, then 500s on the missing avatar asset (must become 200 post-migration)" do
    token = access_token_for(resource_owner_id: @user.id, application_id: @app.id)
    authorize_with(token)

    assert_raises(Sprockets::Rails::Helper::AssetNotFound) do
      get :me, format: :json
    end
  end

  # --- working baseline: valid token, owner not in the application ----------

  test "valid token whose owner is not linked to the application renders Invalid grant and no user" do
    other_app = OauthApplication.create!(
      name: 'Other App',
      redirect_uri: 'https://example.com/other',
      uid: "uid-#{SecureRandom.hex(6)}",
      secret: "secret-#{SecureRandom.hex(6)}"
    )
    token = access_token_for(resource_owner_id: @user.id, application_id: other_app.id)
    authorize_with(token)

    get :me, format: :json

    assert_response :success
    assert_match 'Invalid grant', @response.body
    assert_no_match @user.email, @response.body
  end
end
