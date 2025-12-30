class Settings::HostingsController < ApplicationController
  layout "settings"

  guard_feature unless: -> { self_hosted? }

  before_action :ensure_admin, only: [ :update, :clear_cache ]

  def show
    @breadcrumbs = [
      [ "Home", root_path ],
      [ "Self-Hosting", nil ]
    ]

    # Determine which providers are currently selected
    exchange_rate_provider = ENV["EXCHANGE_RATE_PROVIDER"].presence || Setting.exchange_rate_provider
    securities_provider = ENV["SECURITIES_PROVIDER"].presence || Setting.securities_provider

    # Show Twelve Data settings if either provider is set to twelve_data
    @show_twelve_data_settings = exchange_rate_provider == "twelve_data" || securities_provider == "twelve_data"

    # Show Yahoo Finance settings if either provider is set to yahoo_finance
    @show_yahoo_finance_settings = exchange_rate_provider == "yahoo_finance" || securities_provider == "yahoo_finance"

    # Only fetch provider data if we're showing the section
    if @show_twelve_data_settings
      twelve_data_provider = Provider::Registry.get_provider(:twelve_data)
      @twelve_data_usage = twelve_data_provider&.usage
    end

    if @show_yahoo_finance_settings
      @yahoo_finance_provider = Provider::Registry.get_provider(:yahoo_finance)
    end
  end

  def update
    if hosting_params.key?(:onboarding_state)
      onboarding_state = hosting_params[:onboarding_state].to_s
      Setting.onboarding_state = onboarding_state
    end

    if hosting_params.key?(:require_email_confirmation)
      Setting.require_email_confirmation = hosting_params[:require_email_confirmation]
    end

    if hosting_params.key?(:brand_fetch_client_id)
      Setting.brand_fetch_client_id = hosting_params[:brand_fetch_client_id]
    end

    if hosting_params.key?(:twelve_data_api_key)
      Setting.twelve_data_api_key = hosting_params[:twelve_data_api_key]
    end

    if hosting_params.key?(:exchange_rate_provider)
      Setting.exchange_rate_provider = hosting_params[:exchange_rate_provider]
    end

    if hosting_params.key?(:securities_provider)
      Setting.securities_provider = hosting_params[:securities_provider]
    end

    # OpenAI settings are saved at the family level to allow overriding ENV settings
    if hosting_params.key?(:openai_access_token)
      token_param = hosting_params[:openai_access_token].to_s.strip
      # Ignore blanks and redaction placeholders to prevent accidental overwrite
      unless token_param.blank? || token_param == "********"
        Current.family.openai_access_token = token_param
      end
    end

    # Validate OpenAI configuration before updating
    if hosting_params.key?(:openai_uri_base) || hosting_params.key?(:openai_model)
      validate_openai_config!(
        uri_base: hosting_params[:openai_uri_base],
        model: hosting_params[:openai_model]
      )
    end

    if hosting_params.key?(:openai_uri_base)
      Current.family.openai_uri_base = hosting_params[:openai_uri_base]
    end

    if hosting_params.key?(:openai_model)
      Current.family.openai_model = hosting_params[:openai_model]
    end

    if hosting_params.key?(:openai_json_mode)
      Current.family.openai_json_mode = hosting_params[:openai_json_mode].presence
    end

    # Save family changes
    Current.family.save! if Current.family.changed?

    redirect_to settings_hosting_path, notice: t(".success")
  rescue Setting::ValidationError => error
    flash.now[:alert] = error.message
    render :show, status: :unprocessable_entity
  end

  def clear_cache
    DataCacheClearJob.perform_later(Current.family)
    redirect_to settings_hosting_path, notice: t(".cache_cleared")
  end

  private
    def hosting_params
      params.require(:setting).permit(:onboarding_state, :require_email_confirmation, :brand_fetch_client_id, :twelve_data_api_key, :openai_access_token, :openai_uri_base, :openai_model, :openai_json_mode, :exchange_rate_provider, :securities_provider)
    end

    def ensure_admin
      redirect_to settings_hosting_path, alert: t(".not_authorized") unless Current.user.admin?
    end

    # Validates that a model is provided when a custom URI base is set
    def validate_openai_config!(uri_base: nil, model: nil)
      # Use provided values or current family settings, falling back to global/ENV
      uri_base_value = uri_base.nil? ? (Current.family.openai_uri_base.presence || Setting.openai_uri_base) : uri_base
      model_value = model.nil? ? (Current.family.openai_model.presence || Setting.openai_model) : model

      if uri_base_value.present? && model_value.blank?
        raise Setting::ValidationError, "OpenAI model is required when custom URI base is configured"
      end
    end
end
