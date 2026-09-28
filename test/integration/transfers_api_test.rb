require "test_helper"

class TransfersApiTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_hr
    sign_in(@user)
  end

  test "CSV import returns created count and filtered export is downloadable" do
    post "/api/transfers", params: { csv: File.read(Rails.root.join("public/import-template.csv")) }, as: :json
    assert_response :created
    assert_equal 1, response.parsed_body["count"]
    get "/api/transfers", params: { country: "India" }
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_includes response.headers["Content-Disposition"], "attachment"
    assert_equal 1, CSV.parse(response.body, headers: true).size
    get "/api/transfers", params: { country: "Canada" }
    assert_empty CSV.parse(response.body, headers: true)
  end

  test "invalid import and invalid request shape return actionable errors" do
    post "/api/transfers", params: { csv: "not a CSV" }, as: :json
    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].any?
    post "/api/transfers", params: { csv: [ "invalid" ] }, as: :json
    assert_response :bad_request
    assert_equal 0, Employee.count
  end
end
