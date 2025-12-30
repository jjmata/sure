require "test_helper"

class Provider::RegistryTest < ActiveSupport::TestCase
  test "providers filters out nil values when provider is not configured" do
    # Ensure OpenAI is not configured
    ClimateControl.modify("OPENAI_ACCESS_TOKEN" => nil) do
      Setting.stubs(:openai_access_token).returns(nil)

      registry = Provider::Registry.for_concept(:llm)

      # Should return empty array instead of [nil]
      assert_equal [], registry.providers
    end
  end

  test "providers returns configured providers" do
    # Mock a configured OpenAI provider
    mock_provider = mock("openai_provider")
    Provider::Registry.stubs(:openai).returns(mock_provider)

    registry = Provider::Registry.for_concept(:llm)

    assert_equal [ mock_provider ], registry.providers
  end

  test "get_provider raises error when provider not found for concept" do
    registry = Provider::Registry.for_concept(:llm)

    error = assert_raises(Provider::Registry::Error) do
      registry.get_provider(:nonexistent)
    end

    assert_match(/Provider 'nonexistent' not found for concept: llm/, error.message)
  end

  test "get_provider returns nil when provider not configured" do
    # Ensure OpenAI is not configured
    ClimateControl.modify("OPENAI_ACCESS_TOKEN" => nil) do
      Setting.stubs(:openai_access_token).returns(nil)

      registry = Provider::Registry.for_concept(:llm)

      # Should return nil when provider method exists but returns nil
      assert_nil registry.get_provider(:openai)
    end
  end

  test "openai provider falls back to Setting when ENV is empty string" do
    # Mock ENV to return empty string (common in Docker/env files)
    # Use stub_env helper which properly stubs ENV access
    ClimateControl.modify(
      "OPENAI_ACCESS_TOKEN" => "",
      "OPENAI_URI_BASE" => "",
      "OPENAI_MODEL" => ""
    ) do
      Setting.stubs(:openai_access_token).returns("test-token-from-setting")
      Setting.stubs(:openai_uri_base).returns(nil)
      Setting.stubs(:openai_model).returns(nil)

      provider = Provider::Registry.get_provider(:openai)

      # Should successfully create provider using Setting value
      assert_not_nil provider
      assert_instance_of Provider::Openai, provider
    end
  end

  test "openai provider uses family settings over ENV" do
    # Test that family-level settings take priority over ENV
    ClimateControl.modify(
      "OPENAI_ACCESS_TOKEN" => "env-token",
      "OPENAI_URI_BASE" => "",
      "OPENAI_MODEL" => ""
    ) do
      family = families(:dylan_family)
      family.stubs(:openai_access_token).returns("family-token")
      family.stubs(:openai_uri_base).returns(nil)
      family.stubs(:openai_model).returns(nil)

      provider = Provider::Registry.get_provider(:openai, family: family)

      # Should successfully create provider using family value
      assert_not_nil provider
      assert_instance_of Provider::Openai, provider
    end
  end

  test "openai provider falls back to ENV when family settings are nil" do
    # Test that ENV is used when family settings are not set
    ClimateControl.modify(
      "OPENAI_ACCESS_TOKEN" => "env-token",
      "OPENAI_URI_BASE" => "",
      "OPENAI_MODEL" => ""
    ) do
      family = families(:dylan_family)
      family.stubs(:openai_access_token).returns(nil)
      family.stubs(:openai_uri_base).returns(nil)
      family.stubs(:openai_model).returns(nil)

      provider = Provider::Registry.get_provider(:openai, family: family)

      # Should successfully create provider using ENV value
      assert_not_nil provider
      assert_instance_of Provider::Openai, provider
    end
  end
end
