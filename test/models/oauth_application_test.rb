require 'test_helper'

# Characterization tests for OauthApplication (backed by the `oauth_applications`
# table, the same table Doorkeeper::Application uses). Pins current behavior.
class OauthApplicationTest < ActiveSupport::TestCase
  def build_app(attrs = {})
    defaults = {
      name: 'Sample App',
      uid: "uid-#{SecureRandom.hex(6)}",
      secret: "secret-#{SecureRandom.hex(6)}",
      redirect_uri: 'https://example.com/callback'
    }
    OauthApplication.new(defaults.merge(attrs))
  end

  test "fixtures load and are queryable" do
    assert_equal 'MyString', oauth_applications(:one).name
  end

  # OauthApplication itself declares NO validations (unlike Doorkeeper::Application),
  # so a blank record still saves on this table.
  test "has no model-level validations of its own" do
    app = OauthApplication.new
    assert app.valid?, "OauthApplication declares no validations"
  end

  test "by_name scope orders by name ascending" do
    a = build_app(name: 'Zeta').tap(&:save!)
    b = build_app(name: 'Alpha').tap(&:save!)
    ordered = OauthApplication.by_name.to_a
    assert_operator ordered.index(b), :<, ordered.index(a)
  end

  test "has_many users through user_oauth_applications" do
    app = build_app.tap(&:save!)
    user = users(:admin)
    UserOauthApplication.create!(user: user, oauth_application: app)
    assert_includes app.reload.users, user
    assert_includes app.user_ids, user.id
  end

  test "user_ids= assigns the join through the has_many :through" do
    app = build_app.tap(&:save!)
    app.update_attributes('user_ids' => [users(:admin).id])
    assert_equal [users(:admin).id], app.reload.user_ids
  end

  test "uid uniqueness is enforced at the DB level (unique index)" do
    app = build_app(uid: 'dup-uid-xyz').tap(&:save!)
    dup = build_app(uid: 'dup-uid-xyz')
    assert_raises(ActiveRecord::RecordNotUnique) { dup.save! }
  end
end
