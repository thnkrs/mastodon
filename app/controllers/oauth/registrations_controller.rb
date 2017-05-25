# frozen_string_literal: true

class Oauth::RegistrationsController < DeviseController
  include WithRedisSessionStore
  layout 'auth'

  before_action :check_enabled_registrations, only: [:new, :create]
  before_action :require_omniauth_auth
  before_action :require_no_authentication
  before_action :set_oauth_user

  def new
  end

  def create
    @user.account.username = user_params.dig(:account_attributes, :username)
    @user.skip_confirmation! if @user.valid?

    if @user.save
      sign_in @user
      redirect_to root_path
    else
      render :new
    end
  end

  private

  def set_oauth_user
    @user = User.from_omniauth(omniauth_auth)
    @user.load_facebook_birthday
  end

  def require_omniauth_auth
    redirect_to root_path, alert: t('devise.failure.timeout') unless omniauth_auth
  end

  def omniauth_auth
    @omniauth_auth ||= JSON.parse(redis_session_store('devise.omniauth').get('auth'))
  rescue TypeError, JSON::ParserError
    nil
  end

  def oauth_registration_params
    params.require(:form_oauth_registration).permit(
      :email, :username
    ).merge(locale: I18n.locale)
  end

  def user_params
    params.require(:user).permit(:account_attributes => :username)
  end

  protected

  def check_enabled_registrations
    redirect_to root_path if single_user_mode? || !Setting.open_registrations
  end

end
