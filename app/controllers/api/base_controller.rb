module Api
  class BaseController < ActionController::Base
    protect_from_forgery with: :exception
    before_action :authenticate!
    before_action { response.headers["Cache-Control"] = "no-store" }
    rescue_from ActiveRecord::RecordNotFound do
      render json: { error: "Record not found" }, status: :not_found
    end
    rescue_from ActiveRecord::RecordInvalid do |error|
      render json: { error: error.record.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
    rescue_from ActiveRecord::StaleObjectError, ActiveRecord::RecordNotUnique do
      render json: { error: "This record changed or already exists. Refresh and try again." }, status: :conflict
    end
    rescue_from ActionController::ParameterMissing, ArgumentError do |error|
      render json: { error: error.message }, status: :bad_request
    end
    rescue_from ActionController::InvalidAuthenticityToken do
      render json: { error: "Session expired. Refresh the page." }, status: :unprocessable_entity
    end

    private

    def current_user
      @current_user ||= User.find_by(id: session[:user_id])
    end

    def authenticate!
      render json: { error: "Sign in to continue" }, status: :unauthorized unless current_user
    end
  end
end
