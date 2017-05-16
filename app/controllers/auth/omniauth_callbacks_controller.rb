class Auth::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user.persisted?
      logger.info "#{@user.account.username} Signed In"
      sign_in @user
      redirect_to root_path
    elsif @user.valid?
      session['devise.facebook_data'] = request.env['omniauth.auth']
      redirect_to new_user_registration_url
    else
      logger.warn @user.errors.full_messages

      flash[:notice] = @user.errors.full_messages.join("\n")
      redirect_to new_user_registration_url
    end
  end

  def failure
    flash.now[:alert] = failure_message
    redirect_to root_path
  end
end
