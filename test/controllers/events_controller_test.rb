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

  # --- Themed event show ---

  test "show renders themed event with VS banner" do
    themed = events(:themed_event)
    get event_path(themed)
    assert_response :success
    assert_select "span", text: "VS"
    assert_select "h3", text: /ComStar Forces/
    assert_select "h3", text: /Clan Invasion Force/
  end

  test "show themed event does not display point cap in header" do
    themed = events(:themed_event)
    get event_path(themed)
    assert_response :success
    assert_select "p.text-hud-text-dim", text: /limit/, count: 0
  end

  test "show themed event displays submitted lists grouped by side" do
    themed = events(:themed_event)
    comstar = event_sides(:comstar_side)
    clan = event_sides(:clan_side)
    ArmyList.create!(event: themed, event_side: comstar, player_name: "ComStar Player 1", status: "submitted", submitted_at: 1.day.ago, tech_base: "inner_sphere")
    ArmyList.create!(event: themed, event_side: clan, player_name: "Clan Player 1", status: "submitted", submitted_at: 1.day.ago, tech_base: "clan")

    get event_path(themed)
    assert_response :success
    assert_select "span.font-medium.text-hud-green", text: "ComStar Player 1"
    assert_select "span.font-medium.text-hud-green", text: "Clan Player 1"
  end

  test "show themed event displays empty slots when max_players set" do
    themed = events(:themed_event)
    comstar = event_sides(:comstar_side)
    # comstar_side has max_players: 3, add 1 submitted player -> 2 empty slots
    ArmyList.create!(event: themed, event_side: comstar, player_name: "ComStar Player 1", status: "submitted", submitted_at: 1.day.ago, tech_base: "inner_sphere")

    get event_path(themed)
    assert_response :success
    assert_select "div", text: /wolne miejsca/
  end

  test "show themed event displays side name on draft cards" do
    themed = events(:themed_event)
    comstar = event_sides(:comstar_side)
    draft = ArmyList.create!(event: themed, event_side: comstar, player_name: "ComStar Drafter", status: "draft", tech_base: "inner_sphere")
    set_army_list_cookie([ draft.id ])

    get event_path(themed)
    assert_response :success
    assert_select "span", text: "[ComStar Forces]"
  end

  test "show themed event does not show faction restrictions" do
    themed = events(:themed_event)
    get event_path(themed)
    assert_response :success
    assert_select "span", text: /Frakcje:/, count: 0
  end

  test "show standard event does not display VS banner" do
    get event_path(@event)
    assert_response :success
    assert_select "span", text: "VS", count: 0
  end

  test "show standard event displays point cap in header" do
    get event_path(@event)
    assert_response :success
    assert_select "p", text: /limit 200 PV/
  end

  private

  def set_army_list_cookie(ids)
    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:army_list_ids] = ids
      cookies["army_list_ids"] = cookie_jar[:army_list_ids]
    end
  end
end
