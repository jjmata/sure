module Localize
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
    around_action :switch_timezone
  end

  private
    def switch_locale(&action)
      locale = locale_from_param || Current.family.try(:locale) || locale_from_header || I18n.default_locale
      I18n.with_locale(locale, &action)
    end

    def locale_from_param
      return unless params[:locale].is_a?(String) && params[:locale].present?
      locale = params[:locale].to_sym
      locale if I18n.available_locales.include?(locale)
    end

    def locale_from_header
      header = request.headers["Accept-Language"]
      return if header.blank?

      header.split(",").each do |language_range|
        language = language_range.split(";").first.to_s.strip
        next if language.blank?

        normalized = language.tr("_", "-")
        locales = [ normalized, normalized.split("-").first ].uniq
        locales.each do |candidate|
          locale = candidate.to_sym
          return locale if I18n.available_locales.include?(locale)
        end
      end

      nil
    end

    def switch_timezone(&action)
      timezone = Current.family.try(:timezone) || Time.zone
      Time.use_zone(timezone, &action)
    end
end
