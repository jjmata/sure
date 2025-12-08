require "test_helper"

class Settings::BankSyncControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
  end

  test "should get show" do
    get settings_bank_sync_path
    assert_response :success
  end

  test "should separate providers into BYOKey and bundled categories" do
    get settings_bank_sync_path
    assert_response :success

    # Check that both categories are assigned
    assert_not_nil assigns(:byokey_providers)
    assert_not_nil assigns(:bundled_providers)

    # BYOKey providers should include all four providers (SimpleFIN, Plaid, Enable Banking, Lunch Flow)
    assert_equal 4, assigns(:byokey_providers).length
    byokey_names = assigns(:byokey_providers).map { |p| p[:name] }
    assert_includes byokey_names, "SimpleFIN"
    assert_includes byokey_names, "Plaid"
    assert_includes byokey_names, "Enable Banking (beta)"
    assert_includes byokey_names, "Lunch Flow"

    # Bundled providers should include only Lunch Flow
    assert_equal 1, assigns(:bundled_providers).length
    assert_equal "Lunch Flow", assigns(:bundled_providers).first[:name]
  end

  test "each provider should have sync_methods metadata" do
    get settings_bank_sync_path
    assert_response :success

    # Check BYOKey providers have the :byokey sync method
    assigns(:byokey_providers).each do |provider|
      assert provider[:sync_methods].include?(:byokey),
             "#{provider[:name]} should have :byokey sync method"
    end

    # Check bundled providers have the :bundled sync method
    assigns(:bundled_providers).each do |provider|
      assert provider[:sync_methods].include?(:bundled),
             "#{provider[:name]} should have :bundled sync method"
    end

    # Lunch Flow should support both methods
    lunch_flow_byokey = assigns(:byokey_providers).find { |p| p[:name] == "Lunch Flow" }
    lunch_flow_bundled = assigns(:bundled_providers).find { |p| p[:name] == "Lunch Flow" }

    assert_not_nil lunch_flow_byokey, "Lunch Flow should be in BYOKey providers"
    assert_not_nil lunch_flow_bundled, "Lunch Flow should be in bundled providers"

    assert lunch_flow_byokey[:sync_methods].include?(:byokey)
    assert lunch_flow_byokey[:sync_methods].include?(:bundled)
  end
end
