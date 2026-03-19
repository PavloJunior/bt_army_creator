require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event = events(:upcoming_event)
    @draft_list = army_lists(:draft_list)
  end

  # --- Index ---

  test "index renders successfully" do
    get events_path
    assert_response :success
  end

  test "index shows draft indicator when user has draft for event" do
    set_army_list_cookie([ @draft_list.id ])

    get events_path
    assert_response :success
    assert_select "p", text: /Masz wersję roboczą/
  end

  test "index does not show draft indicator without cookie" do
    get events_path
    assert_response :success
    assert_select "p", text: /Masz wersję roboczą/, count: 0
  end

  # --- Show ---

  test "show renders successfully" do
    get event_path(@event)
    assert_response :success
  end

  test "show displays user's draft lists when cookie is set" do
    set_army_list_cookie([ @draft_list.id ])

    get event_path(@event)
    assert_response :success
    assert_select "h2", text: /Twoje wersje robocze/
    assert_select "a[href='#{event_army_list_path(@event, @draft_list)}']"
  end

  test "show hides drafts section when no cookie" do
    get event_path(@event)
    assert_response :success
    assert_select "h2", text: /Twoje wersje robocze/, count: 0
  end

  test "show hides drafts section when list was submitted" do
    @draft_list.update!(status: "submitted", submitted_at: Time.current)
    set_army_list_cookie([ @draft_list.id ])

    get event_path(@event)
    assert_response :success
    assert_select "h2", text: /Twoje wersje robocze/, count: 0
  end

  test "show displays user's inactive lists when cookie is set" do
    inactive_list = army_lists(:inactive_list)
    set_army_list_cookie([ inactive_list.id ])

    get event_path(@event)
    assert_response :success
    assert_select "h2", text: /Twoje nieaktywne listy/
    assert_select "a[href='#{event_army_list_path(@event, inactive_list)}']"
  end

  test "show hides inactive section when no inactive lists" do
    get event_path(@event)
    assert_response :success
    assert_select "h2", text: /Twoje nieaktywne listy/, count: 0
  end

  test "show handles stale IDs in cookie gracefully" do
    set_army_list_cookie([ 999999 ])

    get event_path(@event)
    assert_response :success
    assert_select "h2", text: /Twoje wersje robocze/, count: 0
  end

  private

  def set_army_list_cookie(ids)
    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:army_list_ids] = ids
      cookies["army_list_ids"] = cookie_jar[:army_list_ids]
    end
  end
end
