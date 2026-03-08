require "test_helper"

class Admin::SyncAttemptsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(User.take)
  end

  test "index requires authentication" do
    sign_out
    get admin_sync_attempts_path
    assert_redirected_to new_admin_session_path
  end

  test "index loads successfully" do
    get admin_sync_attempts_path
    assert_response :success
  end

  test "index shows chassis and sync status" do
    get admin_sync_attempts_path
    assert_response :success
    assert_select "table"
  end

  test "show requires authentication" do
    sign_out
    get admin_sync_attempt_path(sync_attempts(:atlas_completed))
    assert_redirected_to new_admin_session_path
  end

  test "show displays sync attempt details" do
    get admin_sync_attempt_path(sync_attempts(:atlas_completed))
    assert_response :success
  end

  test "show displays failed attempt with errors" do
    get admin_sync_attempt_path(sync_attempts(:commando_failed))
    assert_response :success
  end
end
