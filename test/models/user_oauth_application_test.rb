require 'test_helper'

# Characterization tests for the UserOauthApplication join model.
class UserOauthApplicationTest < ActiveSupport::TestCase
  def make_app
    OauthApplication.create!(
      name: 'App',
      uid: "uid-#{SecureRandom.hex(6)}",
      secret: "secret-#{SecureRandom.hex(6)}",
      redirect_uri: 'https://example.com/callback'
    )
  end

  test "belongs_to user and oauth_application" do
    join = UserOauthApplication.new
    assert_respond_to join, :user
    assert_respond_to join, :oauth_application
  end

  test "persists and links a user to an oauth application" do
    user = users(:admin)
    app = make_app
    join = UserOauthApplication.create!(user: user, oauth_application: app)

    assert_equal user, join.user
    assert_equal app, join.oauth_application
    assert_includes user.oauth_applications, app
    assert_includes app.users, user
  end

  # No validations declared: a join with nil foreign keys still saves.
  test "has no validations - saves with nil associations" do
    join = UserOauthApplication.new
    assert join.valid?
    assert join.save
  end
end
