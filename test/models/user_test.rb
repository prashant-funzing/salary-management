require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "password is hashed and only correct credentials authenticate" do
    user = create_hr
    assert_not_equal "TestPassword123!", user.password_digest
    assert_equal user, user.authenticate("TestPassword123!")
    assert_not user.authenticate("incorrect")
  end

  test "short passwords and duplicate normalized emails are rejected" do
    create_hr
    assert_not User.new(email: " HR@EXAMPLE.COM ", password: "TestPassword123!").valid?
    assert_not User.new(email: "new@example.com", password: "short").valid?
  end
end
