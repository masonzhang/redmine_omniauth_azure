require 'account_controller'
require 'json'
require 'jwt'

class RedmineOauthController < AccountController
  include Helpers::MailHelper
  include Helpers::Checker
  def oauth_azure
    if Setting.plugin_redmine_omniauth_azure['azure_oauth_authentication']
      session[:back_url] = params[:back_url]
      redirect_to oauth_client.auth_code.authorize_url(:redirect_uri => oauth_azure_callback_url, :scope => scopes)
    else
      password_authentication
    end
  end

  def oauth_azure_callback
    if params[:error]
      flash[:error] = l(:notice_access_denied)
      redirect_to signin_path
    else
      token = oauth_client.auth_code.get_token(params[:code], :redirect_uri => oauth_azure_callback_url, :resource => '00000002-0000-0000-c000-000000000000')
      user_info = JWT.decode(token.token, nil, false)
      logger.error user_info

      email = user_info.first['unique_name']

      if email
        checked_try_to_login email, user_info.first
      else
        flash[:error] = l(:notice_no_verified_email_we_could_use)
        redirect_to signin_path
      end
    end
  end

  def checked_try_to_login(email, user)
    if allowed_domain_for?(email)
      try_to_login email, user
    else
      flash[:error] = l(:notice_domain_not_allowed, :domain => parse_email(email)[:domain])
      redirect_to signin_path
    end
  end

  def try_to_login email, info
    params[:back_url] = session[:back_url]
    session.delete(:back_url)
    logger.error 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa2i11111111111111111111111111'

    user = User.joins(:email_addresses)
               .where('email_addresses.address' => email, 'email_addresses.is_default' => true)
               .first_or_initialize
    logger.error user
    logger.error 'userxxxxxx'
    if user.new_record?
      logger.error 'bbbbbbb'
      # Self-registration off
      #redirect_to(home_url) && return unless !Setting.plugin_redmine_omniauth_azure['azure_oauth_injection']
      # Create on the fly
      user.firstname, user.lastname = info['name'].split(' ') unless info['name'].nil?
      user.firstname ||= info['name']
      user.lastname ||= info['name']
      user.mail = email
      user.login = email
      user.random_password
      user.register

      if (Setting.plugin_redmine_omniauth_azure['azure_oauth_injection'])
        logger.error '11111111111111111111111111'
        register_automatically(user) do
          logger.error '222222222222222222222'
          onthefly_creation_failed(user)
        end
      else
        case Setting.self_registration
        when '1'
          register_by_email_activation(user) do
            onthefly_creation_failed(user)
          end
        when '3'
          register_automatically(user) do
            onthefly_creation_failed(user)
          end
        else
          register_manually_by_administrator(user) do
            onthefly_creation_failed(user)
          end
        end
      end
    else
      # Existing record
      if user.active?
        successful_authentication(user)
      else
        account_pending
      end
    end
  end

  def oauth_client
    @client ||= OAuth2::Client.new(settings['client_id'], settings['client_secret'],
      :site => 'https://login.windows.net',
      :authorize_url => '/' + settings['tenant_id'] + '/oauth2/authorize',
      :token_url => '/' + settings['tenant_id'] + '/oauth2/token')
  end

  def settings
    @settings ||= Setting.plugin_redmine_omniauth_azure
  end

  def scopes
    'user:email'
  end
end