# frozen_string_literal: true

class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, I18n.t('users.invalid_email')) if blocked_email?(value)
    record.errors.add(attribute, I18n.t('users.invalid_email_domain')) if record.birthday.blank? && !academic_account?(value)
  end

  private

  def blocked_email?(value)
    on_blacklist?(value) || not_on_whitelist?(value)
  end

  def on_blacklist?(value)
    return false if Rails.configuration.x.email_domains_blacklist.blank?

    domains = Rails.configuration.x.email_domains_blacklist.gsub('.', '\.')
    regexp = Regexp.new("@(.+\\.)?(#{domains})", true)

    value =~ regexp
  end

  def not_on_whitelist?(value)
    return false if Rails.configuration.x.email_domains_whitelist.blank?

    domains = Rails.configuration.x.email_domains_whitelist.gsub('.', '\.')
    regexp = Regexp.new("@(.+\\.)?(#{domains})$", true)

    value !~ regexp
  end

  def academic_account?(value)
    value.end_with?(*%w[.ac.jp .edu thinkers.jp])
  end
end
