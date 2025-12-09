class Settings::BankSyncController < ApplicationController
  layout "settings"

  def show
    # Load providers from configuration file
    all_providers = load_providers

    # In self-hosted mode, show simple list; in hosted mode, separate by sync method
    if self_hosted?
      @providers = all_providers
    else
      @byokey_providers = all_providers.select { |p| p[:sync_methods].include?(:byokey) }
      @bundled_providers = all_providers.select { |p| p[:sync_methods].include?(:bundled) }
    end
  end

  private
    def load_providers
      config_path = Rails.root.join("config", "sync-providers.yml")
      
      begin
        config = YAML.safe_load_file(config_path)
        
        config["providers"].map do |provider|
          {
            name: provider["name"],
            description: provider["description"],
            path: provider["path"],
            target: provider["target"],
            rel: provider["rel"],
            sync_methods: provider["sync_methods"].map(&:to_sym)
          }
        end
      rescue Errno::ENOENT, Psych::SyntaxError => e
        Rails.logger.error("Failed to load sync providers config: #{e.message}")
        []
      end
    end
end
