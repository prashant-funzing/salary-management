require "test_helper"

class SessionsApiTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_hr
    @previous_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end
  teardown { Rails.cache = @previous_cache }

  test "anonymous session provides CSRF token without exposing credentials" do
    get "/api/session"
    assert_response :success
    assert_nil response.parsed_body["user"]
    assert response.parsed_body["csrf_token"].present?
    assert_equal "no-store", response.headers["Cache-Control"]
  end

  test "unknown users and incorrect passwords have the same response" do
    [ [ "unknown@example.com", "bad" ], [ @user.email, "bad" ] ].each do |email, password|
      post "/api/session", params: { email: email, password: password }, as: :json
      assert_response :unauthorized
      assert_equal "Invalid email or password", response.parsed_body["error"]
    end
  end

  test "login normalizes email and logout clears session" do
    post "/api/session", params: { email: " HR@EXAMPLE.COM ", password: "TestPassword123!" }, as: :json
    assert_response :success
    get "/api/session"
    assert_equal({ "email" => @user.email }, response.parsed_body["user"])
    delete "/api/session"
    assert_response :no_content
    get "/api/session"
    assert_nil response.parsed_body["user"]
  end

  test "failed login attempts are limited and expire after fifteen minutes" do
    travel_to Time.utc(2026, 1, 1) do
      10.times do
        post "/api/session", params: { email: @user.email, password: "wrong" }, as: :json
        assert_response :unauthorized
      end
      post "/api/session", params: { email: @user.email, password: "TestPassword123!" }, as: :json
      assert_response :too_many_requests
      travel 16.minutes
      sign_in(@user)
    end
  end

  test "successful login clears preceding failed attempts" do
    9.times { post "/api/session", params: { email: @user.email, password: "bad" }, as: :json }
    sign_in(@user)
    delete "/api/session"
    post "/api/session", params: { email: @user.email, password: "bad" }, as: :json
    assert_response :unauthorized
    sign_in(@user)
  end

end
