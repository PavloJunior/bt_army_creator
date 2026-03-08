require "test_helper"

class SyncChassisJobTest < ActiveJob::TestCase
  setup do
    @chassis = chassis(:atlas)
    # Matches real MUL API response structure from /Unit/QuickList
    @fake_variants_data = [
      {
        "Id" => 7433, "Name" => "Atlas AS7-A", "Variant" => "AS7-A",
        "Class" => "Atlas", "GroupName" => "",
        "BattleValue" => 1897, "BFPointValue" => 52, "Tonnage" => 100,
        "Type" => { "Id" => 18, "Name" => "BattleMech", "Image" => "BattleMech.gif", "SortOrder" => 0 },
        "Technology" => { "Id" => 1, "Name" => "Inner Sphere", "Image" => nil, "SortOrder" => 0 },
        "Role" => { "Id" => 105, "Name" => "Juggernaut", "Image" => nil, "SortOrder" => 1 },
        "DateIntroduced" => "2755", "EraId" => 3, "EraStart" => 2571,
        "EraIcon" => "https://i.ibb.co/example/era.png",
        "Rules" => "Standard", "Cost" => 10_235_000,
        "ImageUrl" => "https://i.ibb.co/VtHKQ7Q/atlas-rg.png",
        "IsFeatured" => true, "IsPublished" => true, "Release" => 1.0,
        "TROId" => 1, "TRO" => "TRO:3025", "RSId" => 1, "RS" => "None",
        "BFType" => "BM", "BFMove" => "3\"", "BFTMM" => 0,
        "BFArmor" => 9, "BFStructure" => 4, "BFThreshold" => 0,
        "BFDamageShort" => 4, "BFDamageShortMin" => false,
        "BFDamageMedium" => 4, "BFDamageMediumMin" => false,
        "BFDamageLong" => 2, "BFDamageLongMin" => false,
        "BFDamageExtreme" => 0, "BFDamageExtemeMin" => false,
        "BFSize" => 4, "BFOverheat" => 2, "BFAbilities" => "AC 2/2/2",
        "Skill" => 0, "FormatedTonnage" => "100"
      }
    ]
  end

  test "creates sync_attempt and enqueues faction and card jobs" do
    stub_mul_client do
      SyncChassisJob.perform_now(@chassis.id)
    end

    attempt = @chassis.sync_attempts.last
    assert_not_nil attempt
    assert_includes %w[running completed], attempt.status
    assert attempt.variants_count > 0
    assert attempt.factions_total > 0
    assert_not_nil attempt.started_at
  end

  test "enqueues one SyncFactionForChassisJob per faction" do
    stub_mul_client do
      assert_enqueued_jobs Faction.count, only: SyncFactionForChassisJob do
        SyncChassisJob.perform_now(@chassis.id)
      end
    end
  end

  test "marks attempt failed on error" do
    # Use StandardError instead of ApiError to bypass retry_on
    original = MulClient.method(:fetch_variants)
    MulClient.define_singleton_method(:fetch_variants) { |*args, **kwargs| raise StandardError, "test error" }

    begin
      assert_raises(StandardError) do
        SyncChassisJob.perform_now(@chassis.id)
      end
    ensure
      MulClient.define_singleton_method(:fetch_variants, original)
    end

    attempt = @chassis.sync_attempts.last
    assert_equal "failed", attempt.status
    assert_includes attempt.error_messages.first, "test error"
  end

  test "filters out variants belonging to other chassis with similar names" do
    # Simulate MUL API returning partial matches (e.g., searching "Atlas" also returns "Atlas II")
    mixed_data = @fake_variants_data + [
      {
        "Id" => 9999, "Name" => "Atlas II AS7-D-H2", "Variant" => "AS7-D-H2",
        "Class" => "Atlas II", "GroupName" => "",
        "BattleValue" => 2100, "BFPointValue" => 55, "Tonnage" => 100,
        "Type" => { "Id" => 18, "Name" => "BattleMech", "Image" => "BattleMech.gif", "SortOrder" => 0 },
        "Technology" => { "Id" => 1, "Name" => "Inner Sphere", "Image" => nil, "SortOrder" => 0 },
        "Role" => { "Id" => 105, "Name" => "Juggernaut", "Image" => nil, "SortOrder" => 1 },
        "DateIntroduced" => "3130", "EraId" => 7, "EraStart" => 3081,
        "EraIcon" => "https://i.ibb.co/example/era.png",
        "Rules" => "Standard", "Cost" => 12_000_000,
        "ImageUrl" => "https://i.ibb.co/example/atlas2.png",
        "IsFeatured" => false, "IsPublished" => true, "Release" => 1.0,
        "TROId" => 1, "TRO" => "TRO:3145", "RSId" => 1, "RS" => "None",
        "BFType" => "BM", "BFMove" => "3\"", "BFTMM" => 0,
        "BFArmor" => 10, "BFStructure" => 4, "BFThreshold" => 0,
        "BFDamageShort" => 5, "BFDamageShortMin" => false,
        "BFDamageMedium" => 5, "BFDamageMediumMin" => false,
        "BFDamageLong" => 3, "BFDamageLongMin" => false,
        "BFDamageExtreme" => 0, "BFDamageExtemeMin" => false,
        "BFSize" => 4, "BFOverheat" => 2, "BFAbilities" => "AC 2/2/2",
        "Skill" => 0, "FormatedTonnage" => "100"
      }
    ]

    original = MulClient.method(:fetch_variants)
    MulClient.define_singleton_method(:fetch_variants) { |*args, **kwargs| mixed_data }
    begin
      SyncChassisJob.perform_now(@chassis.id)
    ensure
      MulClient.define_singleton_method(:fetch_variants, original)
    end

    # Only the Atlas variant should be saved, not Atlas II
    variant_classes = @chassis.variants.reload.pluck(:name)
    assert_includes variant_classes, "Atlas AS7-A"
    refute variant_classes.any? { |n| n.include?("Atlas II") }
    assert_nil Variant.find_by(mul_id: 9999)
  end

  test "sets factions_total to number of factions" do
    stub_mul_client do
      SyncChassisJob.perform_now(@chassis.id)
    end

    attempt = @chassis.sync_attempts.last
    assert_equal Faction.count, attempt.factions_total
  end

  private

  def stub_mul_client(&block)
    data = @fake_variants_data
    original = MulClient.method(:fetch_variants)
    MulClient.define_singleton_method(:fetch_variants) { |*args, **kwargs| data }
    yield
  ensure
    MulClient.define_singleton_method(:fetch_variants, original)
  end
end
