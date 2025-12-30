class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Returns the human-readable name for an enum value
  def self.human_enum_name(enum_name, enum_value)
    return "" if enum_value.blank?

    # Try I18n first, fall back to humanize
    I18n.t("activerecord.enums.#{model_name.i18n_key}.#{enum_name}.#{enum_value}", default: enum_value.to_s.humanize)
  end

  # Instance method for convenience
  def human_enum_name(enum_name)
    self.class.human_enum_name(enum_name, self.send(enum_name))
  end
end
