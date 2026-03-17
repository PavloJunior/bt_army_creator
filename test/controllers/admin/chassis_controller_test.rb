require "test_helper"

class Admin::ChassisControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(User.take)
  end

  # batch_create tests

  test "batch_create creates multiple chassis independently" do
    assert_difference "Chassis.count", 2 do
      post batch_create_admin_chassis_index_path, params: {
        chassis_names: [ "Test Mech A", "Test Mech B" ],
        miniature_count: 2
      }
    end

    a = Chassis.find_by(name: "Test Mech A")
    b = Chassis.find_by(name: "Test Mech B")
    assert_nil a.mini_group_id
    assert_nil b.mini_group_id
    assert_equal 2, a.miniatures.count
    assert_equal 2, b.miniatures.count
    assert_redirected_to admin_chassis_index_path
  end

  test "batch_create creates shared group with mini_group_id" do
    assert_difference "Chassis.count", 2 do
      post batch_create_admin_chassis_index_path, params: {
        chassis_names: [ "Shared A", "Shared B" ],
        miniature_count: 3,
        shared: "true"
      }
    end

    a = Chassis.find_by(name: "Shared A")
    b = Chassis.find_by(name: "Shared B")
    assert_not_nil a.mini_group_id
    assert_equal a.mini_group_id, b.mini_group_id
  end

  test "batch_create creates miniatures on first chassis only for shared" do
    post batch_create_admin_chassis_index_path, params: {
      chassis_names: [ "Pool A", "Pool B" ],
      miniature_count: 3,
      shared: "true"
    }

    a = Chassis.find_by(name: "Pool A")
    b = Chassis.find_by(name: "Pool B")
    assert_equal 3, a.miniatures.count
    assert_equal 0, b.miniatures.count
    assert_equal 3, a.miniatures_pool.count
    assert_equal 3, b.miniatures_pool.count
  end

  test "batch_create skips already existing chassis" do
    assert_difference "Chassis.count", 0 do
      post batch_create_admin_chassis_index_path, params: {
        chassis_names: [ "Atlas" ],
        miniature_count: 1
      }
    end
    assert_redirected_to admin_chassis_index_path
  end

  test "batch_create with empty names redirects with alert" do
    post batch_create_admin_chassis_index_path, params: { chassis_names: [ "" ] }
    assert_redirected_to new_admin_chassis_path
  end

  # link tests

  test "link joins two ungrouped chassis into a group" do
    atlas = chassis(:atlas)
    commando = chassis(:commando)

    post link_admin_chassis_path(atlas), params: { target_chassis_id: commando.id }

    atlas.reload
    commando.reload
    assert_not_nil atlas.mini_group_id
    assert_equal atlas.mini_group_id, commando.mini_group_id
    assert_redirected_to admin_chassis_path(atlas)
  end

  test "link merges chassis into existing group" do
    gauss = chassis(:schrek_gauss)
    atlas = chassis(:atlas)

    post link_admin_chassis_path(gauss), params: { target_chassis_id: atlas.id }

    gauss.reload
    atlas.reload
    ppc = chassis(:schrek_ppc).reload
    assert_equal gauss.mini_group_id, atlas.mini_group_id
    assert_equal gauss.mini_group_id, ppc.mini_group_id
  end

  test "link merges two different groups" do
    atlas = chassis(:atlas)
    commando = chassis(:commando)
    atlas.update!(mini_group_id: "group-a")
    commando.update!(mini_group_id: "group-b")

    gauss = chassis(:schrek_gauss)
    # gauss is in shared-schrek-group with ppc

    post link_admin_chassis_path(atlas), params: { target_chassis_id: gauss.id }

    atlas.reload
    commando.reload
    gauss.reload
    ppc = chassis(:schrek_ppc).reload

    # atlas, gauss, and ppc should now share a group; commando keeps its own (it wasn't in atlas's original group for this test)
    assert_equal atlas.mini_group_id, gauss.mini_group_id
    assert_equal atlas.mini_group_id, ppc.mini_group_id
  end

  # unlink tests

  test "unlink removes chassis from group" do
    gauss = chassis(:schrek_gauss)
    post_path = unlink_admin_chassis_path(gauss)
    delete post_path

    gauss.reload
    assert_nil gauss.mini_group_id
    assert_redirected_to admin_chassis_path(gauss)
  end

  test "unlink cleans up solo group member" do
    gauss = chassis(:schrek_gauss)
    ppc = chassis(:schrek_ppc)

    delete unlink_admin_chassis_path(gauss)

    gauss.reload
    ppc.reload
    assert_nil gauss.mini_group_id
    assert_nil ppc.mini_group_id
  end
end
