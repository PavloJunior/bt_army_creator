require "test_helper"

class SiteAccessControllerTest < ActionDispatch::IntegrationTest
  # --- Gate disabled (no SITE_PASSWORD) ---

  test "public pages accessible when SITE_PASSWORD is not set" do
    ClimateControl.modify SITE_PASSWORD: nil do
      get events_path
      assert_response :success
    end
  end

  test "public pages accessible when SITE_PASSWORD is blank" do
    ClimateControl.modify SITE_PASSWORD: "" do
      get events_path
      assert_response :success
    end
  end

  # --- Gate enabled ---

  test "redirects to /access when SITE_PASSWORD is set and no cookie" do
    ClimateControl.modify SITE_PASSWORD: "sekret" do
      get events_path
      assert_redirected_to site_access_path
    end
  end

  test "lock screen renders successfully" do
    ClimateControl.modify SITE_PASSWORD: "sekret" do
      get site_access_path
      assert_response :success
      assert_select "input[type=password]"
    end
  end

  test "correct password sets cookie and redirects to root" do
    ClimateControl.modify SITE_PASSWORD: "sekret" do
      post site_access_path, params: { password: "sekret" }
      assert_redirected_to root_path
      assert cookies[:site_access_granted].present?
    end
  end

  test "correct password redirects to stored return-to path" do
    ClimateControl.modify SITE_PASSWORD: "sekret" do
      get events_path
      assert_redirected_to site_access_path

      post site_access_path, params: { password: "sekret" }
      assert_redirected_to events_path
    end
  end

  test "wrong password re-renders form with error" do
    ClimateControl.modify SITE_PASSWORD: "sekret" do
      post site_access_path, params: { password: "wrong" }
      assert_response :unprocessable_entity
      assert_select "input[type=password]"
    end
  end

  test "valid cookie grants access without re-entering password" do
    ClimateControl.modify SITE_PASSWORD: "sekret" do
      # First, authenticate
      post site_access_path, params: { password: "sekret" }
      assert_redirected_to root_path

      # Now access public pages with the cookie
      get events_path
      assert_response :success
    end
  end

  test "cookie is invalidated when SITE_PASSWORD changes" do
    ClimateControl.modify SITE_PASSWORD: "sekret" do
      post site_access_path, params: { password: "sekret" }
      assert_redirected_to root_path
    end

    ClimateControl.modify SITE_PASSWORD: "new_password" do
      get events_path
      assert_redirected_to site_access_path
    end
  end

  # --- Admin does NOT bypass gate ---

  test "authenticated admin is still gated on public pages" do
    ClimateControl.modify SITE_PASSWORD: "sekret" do
      sign_in_as(User.take)
      get events_path
      assert_redirected_to site_access_path
    end
  end

  test "admin login page is accessible without site password" do
    ClimateControl.modify SITE_PASSWORD: "sekret" do
      get new_admin_session_path
      assert_response :success
    end
  end

  # --- No redirect loop ---

  test "site access page does not redirect to itself" do
    ClimateControl.modify SITE_PASSWORD: "sekret" do
      get site_access_path
      assert_response :success
    end
  end

  # --- Health check not gated ---

  test "health check endpoint is not gated" do
    ClimateControl.modify SITE_PASSWORD: "sekret" do
      get rails_health_check_path
      assert_response :success
    end
  end
end
