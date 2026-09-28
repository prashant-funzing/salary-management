module Api
  class SessionsController < BaseController
    skip_before_action :authenticate!, only: [ :show, :create ]

    def show
      render json: { user: current_user&.slice(:email), csrf_token: form_authenticity_token }
    end

    def create
      key = "login:#{request.remote_ip}"
      attempts = Rails.cache.read(key).to_i
      return render json: { error: "Too many attempts. Try again in 15 minutes." }, status: :too_many_requests if attempts >= 10
      Rails.cache.write(key, attempts + 1, expires_in: 15.minutes)
      user = User.find_by(email: params[:email].to_s.strip.downcase)
      if user&.authenticate(params[:password].to_s)
        reset_session
        session[:user_id] = user.id
        Rails.cache.delete(key)
        render json: { user: user.slice(:email), csrf_token: form_authenticity_token }
      else
        render json: { error: "Invalid email or password" }, status: :unauthorized
      end
    end

    def destroy
      reset_session
      head :no_content
    end
  end
end
