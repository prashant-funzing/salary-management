module Api
  class SessionsController < BaseController
    MAX_LOGIN_ATTEMPTS = 10
    LOGIN_ATTEMPT_WINDOW = 15.minutes

    skip_before_action :authenticate!, only: [ :show, :create ]
    before_action :check_login_attempts, only: :create

    def show
      render json: session_payload(current_user)
    end

    def create
      user = User.find_by(email: params[:email].to_s.strip.downcase)

      if user&.authenticate(params[:password].to_s)
        establish_session(user)
        render json: session_payload(user)
      else
        render json: { error: "Invalid email or password" }, status: :unauthorized
      end
    end

    def destroy
      reset_session
      head :no_content
    end

    private

    def check_login_attempts
      attempts = Rails.cache.read(login_attempts_key).to_i

      if attempts >= MAX_LOGIN_ATTEMPTS
        render json: { error: "Too many attempts. Try again in 15 minutes." },
          status: :too_many_requests
      else
        Rails.cache.write(login_attempts_key, attempts + 1, expires_in: LOGIN_ATTEMPT_WINDOW)
      end
    end

    def login_attempts_key
      "login:#{request.remote_ip}"
    end

    def establish_session(user)
      reset_session
      session[:user_id] = user.id
      Rails.cache.delete(login_attempts_key)
    end

    def session_payload(user)
      { user: user&.slice(:email), csrf_token: form_authenticity_token }
    end
  end
end
