require 'redmine'
require_dependency 'redmine_omniauth_azure/hooks'

Redmine::Plugin.register :redmine_omniauth_azure do
  name 'Redmine Omniauth Azure plugin'
  author 'JoyMoe IT'
  description 'This is a plugin for Redmine authentication through Azure AD'
  version '0.0.1'
  url 'https://git.shido.cn/IT/redmine_omniauth_azure'
  author_url 'https://git.shido.cn/IT'

  settings :default => {
    :client_id => '',
    :client_secret => '',
    :azure_oauth_authentication => false,
    :allowed_domains => ''
  }, :partial => 'settings/azure_settings'
end
