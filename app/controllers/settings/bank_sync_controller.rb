class Settings::BankSyncController < ApplicationController
  layout "settings"

  def show
    # Define all providers with their sync method support
    all_providers = [
      {
        name: "Lunch Flow",
        description: "US, Canada, UK, EU, Brazil and Asia through multiple open banking providers.",
        path: "https://lunchflow.app/features/sure-integration",
        target: "_blank",
        rel: "noopener noreferrer",
        sync_methods: [ :bundled, :byokey ] # Lunch Flow supports both
      },
      {
        name: "Plaid",
        description: "US & Canada bank connections with transactions, investments, and liabilities.",
        path: "https://github.com/we-promise/sure/blob/main/docs/hosting/plaid.md",
        target: "_blank",
        rel: "noopener noreferrer",
        sync_methods: [ :byokey ]
      },
      {
        name: "SimpleFIN",
        description: "US & Canada connections via SimpleFIN protocol.",
        path: "https://beta-bridge.simplefin.org",
        target: "_blank",
        rel: "noopener noreferrer",
        sync_methods: [ :byokey ]
      },
      {
        name: "Enable Banking (beta)",
        description: "European bank connections via open banking APIs across multiple countries.",
        path: "https://enablebanking.com",
        target: "_blank",
        rel: "noopener noreferrer",
        sync_methods: [ :byokey ]
      }
    ]

    # In self-hosted mode, show simple list; in hosted mode, separate by sync method
    if self_hosted?
      @providers = all_providers
    else
      @byokey_providers = all_providers.select { |p| p[:sync_methods].include?(:byokey) }
      @bundled_providers = all_providers.select { |p| p[:sync_methods].include?(:bundled) }
    end
  end
end
