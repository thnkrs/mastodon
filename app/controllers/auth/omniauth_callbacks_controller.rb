class Auth::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include WithRedisSessionStore

  def facebook
    @user = User.from_omniauth(request.env['omniauth.auth'])

    # ログイン済みユーザーならroot_path遷移
    if @user.persisted?
      sign_in @user
      redirect_to root_path
      return
    end

    # 未ログインのFacebookユーザーならRedisセッションストア(Redisのもの, Pawoo 53caf76 由来)に保存し、Facebook経由専用の登録画面に遷移
    store_omniauth_auth
    redirect_to new_user_oauth_registration_path
  end

  def failure
    flash.now[:alert] = failure_message
    redirect_to root_path
  end

  private

  def store_omniauth_auth
    redis_session_store('devise.omniauth') do |redis|
      redis.setex('auth', 30.minutes, request.env['omniauth.auth'].to_json)
    end
  end

end
