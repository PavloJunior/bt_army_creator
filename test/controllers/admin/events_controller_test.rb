require "test_helper"

module Admin
  class EventsControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in_as(User.take)
    end

    test "creating a shared_army_list event auto-creates a draft list with chosen tech_base" do
      assert_difference "Event.count", 1 do
        assert_difference "ArmyList.count", 1 do
          post admin_events_path, params: {
            event: {
              name: "Scouring Sands Admin Create",
              date: "2026-07-01",
              game_system: "alpha_strike",
              point_cap: 400,
              shared_army_list: "1",
              shared_tech_base: "inner_sphere"
            }
          }
        end
      end

      event = Event.find_by(name: "Scouring Sands Admin Create")
      assert event.shared_army_list?
      list = event.shared_army_list_record
      assert_not_nil list
      assert_equal "inner_sphere", list.tech_base
      assert_equal "draft", list.status
      assert_redirected_to admin_event_path(event)
    end

    test "creating a shared_army_list event without tech_base re-renders with an error" do
      assert_no_difference "Event.count" do
        post admin_events_path, params: {
          event: {
            name: "Bad Shared",
            date: "2026-07-01",
            game_system: "alpha_strike",
            point_cap: 400,
            shared_army_list: "1",
            shared_tech_base: ""
          }
        }
      end
      assert_response :unprocessable_entity
    end

    test "creating an event with both shared_army_list and themed checked is invalid" do
      assert_no_difference "Event.count" do
        post admin_events_path, params: {
          event: {
            name: "Impossible",
            date: "2026-07-01",
            game_system: "alpha_strike",
            point_cap: 400,
            themed: "1",
            shared_army_list: "1",
            shared_tech_base: "mixed"
          },
          sides: [
            { name: "A", point_cap: 200, position: 1 },
            { name: "B", point_cap: 200, position: 2 }
          ]
        }
      end
      assert_response :unprocessable_entity
    end

    test "updating a shared event's tech_base on a draft empty list flows through" do
      event = Event.create!(
        name: "Update Tech",
        date: "2026-07-01",
        game_system: "alpha_strike",
        point_cap: 400,
        status: "upcoming",
        shared_army_list: true,
        shared_tech_base: "inner_sphere"
      )

      patch admin_event_path(event), params: {
        event: {
          name: event.name,
          date: event.date.to_s,
          game_system: event.game_system,
          point_cap: event.point_cap,
          shared_army_list: "1",
          shared_tech_base: "clan"
        }
      }

      assert_redirected_to admin_event_path(event)
      assert_equal "clan", event.shared_army_list_record.reload.tech_base
    end

    test "updating a shared event's tech_base is rejected when items already exist" do
      event = Event.create!(
        name: "Locked Tech",
        date: "2026-07-01",
        game_system: "alpha_strike",
        point_cap: 400,
        status: "upcoming",
        shared_army_list: true,
        shared_tech_base: "inner_sphere"
      )
      event.shared_army_list_record.army_list_items.create!(
        miniature: miniatures(:atlas_mini),
        variant: variants(:atlas_d),
        skill: 4
      )

      patch admin_event_path(event), params: {
        event: {
          name: event.name,
          date: event.date.to_s,
          game_system: event.game_system,
          point_cap: event.point_cap,
          shared_army_list: "1",
          shared_tech_base: "clan"
        }
      }

      assert_response :unprocessable_entity
      assert_equal "inner_sphere", event.shared_army_list_record.reload.tech_base
    end
  end
end
