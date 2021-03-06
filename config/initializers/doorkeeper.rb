Doorkeeper.configure do
  use_refresh_token
  access_token_expires_in 2.hours
  access_token_methods :from_bearer_authorization

  resource_owner_from_credentials do |routes|
    user = User.find_for_database_authentication(provider: :email, email: params[:email])
    if user && user.valid_for_authentication? { user.valid_password?(params[:password]) }
      user
    end
  end

  resource_owner_from_assertion do
    app = Doorkeeper::Application.by_uid_and_secret(params[:client_id], params[:client_secret])
    if app.blank?
      Rails.logger.info "Invalid Client"
    end

    external_auth = "Doorkeeper::ExternalAuth::#{params[:provider].try(:classify)}".safe_constantize.try(:new, params[:assertion])
    if external_auth.respond_to? :secret and params[:secret].present?
      external_auth.secret = params[:secret]
    end

    if external_auth.blank?
      Rails.logger.info "Provider not found : #{params[:provider]}"
      raise Doorkeeper::Errors::DoorkeeperError.new(:invalid_external_auth_provider)
    end

    begin
      user = User.find_by uid: external_auth.uid, provider: external_auth.provider
      if user.present?
        user
      elsif params[:user].try(:fetch, :nickname, nil).present?
        email = external_auth.email || params[:user].try(:fetch, :email, nil)
        if email.present?
          User.create_by_external_auth! external_auth, params[:user][:nickname], email
        else
          raise Doorkeeper::Errors::DoorkeeperError.new(:need_nickname_and_email)
        end
      else
        if external_auth.email.present?
          raise Doorkeeper::Errors::DoorkeeperError.new(:need_nickname)
        else
          raise Doorkeeper::Errors::DoorkeeperError.new(:need_nickname_and_email)
        end
      end
    rescue Doorkeeper::Errors::DoorkeeperError => e
      raise e
    rescue => e
      if User.exists? nickname: params[:user].try(:fetch, :nickname, nil)
        raise Doorkeeper::Errors::DoorkeeperError.new(:duplicate_nickname)
      elsif external_auth.email.blank?
        raise Doorkeeper::Errors::DoorkeeperError.new(:invalid_external_auth_email)
      else
        raise e
      end
    end
  end

  # resource_owner_authenticator do
  #   User.first
  # end

  # add your supported grant types and other extensions
  grant_flows %w(assertion password)
  #  authorization_code implicit password client_credentials

  admin_authenticator do |routes|
    redirect_to root_url unless current_user.try(:admin?)
  end
end

# Doorkeeper.configuration.token_grant_types << "password"
