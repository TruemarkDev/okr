class UserOauthApplication < ApplicationRecord
  belongs_to :user
  belongs_to :oauth_application
end
