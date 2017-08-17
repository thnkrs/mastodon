class Auth::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include WithRedisSessionStore

  def facebook
    @user = User.from_omniauth(request.env['omniauth.auth'])

    # ログイン済みユーザーならroot_path遷移
    # 但しアプリから入ってきた場合はリダイレクト先が違う
    if @user.persisted?
      sign_in @user

      # Auth::SessionsController#after_sign_in_path_for と同等の処理
      last_url = stored_location_for(:user)
      if [about_path].include?(last_url)
        next_path = root_path
      else
        next_path = last_url || root_path
      end

      redirect_to next_path
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
