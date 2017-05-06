module V1
  class Base < Grape::API
    mount V1::Users
    mount V1::Comments
    mount V1::Upvotes
    mount V1::Votings
    mount V1::Feedbacks
    mount V1::Parties
    mount V1::Groups
    mount V1::Posts
    mount V1::Messages
    mount V1::Invitations
    mount V1::Tags
    mount V1::DeviceTokens
    mount V1::Settings
    mount V1::AppVersion
  end
end
