# frozen_string_literal: true
module WineBouncerExtensions
  module OAuth2
    #monkeypatch protection behavior. This method shares the given token with the endpoints even if they aren't protected.
    def before
      set_auth_strategy(WineBouncer.configuration.auth_strategy)
      auth_strategy.api_context = context
      #extend the context with auth methods.
      context.extend(WineBouncer::AuthMethods)
      context.protected_endpoint = endpoint_protected?
      self.doorkeeper_request= env # set request for later use.
      if context.protected_endpoint? or valid_doorkeeper_token?(*auth_scopes)
        doorkeeper_authorize!(*auth_scopes)
      end
      context.doorkeeper_access_token = doorkeeper_token
    end
  end
end
WineBouncer::OAuth2.prepend WineBouncerExtensions::OAuth2

WineBouncer.configure do |config|
  config.auth_strategy = :default

  config.define_resource_owner do
    User.find(doorkeeper_access_token.resource_owner_id) if doorkeeper_access_token
  end
end
