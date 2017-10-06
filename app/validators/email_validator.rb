# frozen_string_literal: true

class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add(attribute, I18n.t('users.invalid_email')) if blocked_email?(value)
    record.errors.add(attribute, I18n.t('users.invalid_email_domain')) if !record.facebook_login? && !academic_account?(value)
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
    value.end_with?(*%w[.ac.jp .ac.uk .edu .edu.au @thinkers.jp .thinkers.jp @aoyama.jp .aoyama.jp @chiba-u.jp .chiba-u.jp @gob-ip.net .gob-ip.net @hgu.jp .hgu.jp @keio.jp .keio.jp @naist.jp .naist.jp @oecu.jp .oecu.jp @oist.jp .oist.jp @ous.jp .ous.jp @sendai-nct.jp .sendai-nct.jp @senshu-u.jp .senshu-u.jp @tokai-u.jp .tokai-u.jp @toyo.jp .toyo.jp @waseda.jp .waseda.jp @chibakoudai.jp .chibakoudai.jp @gakken.co.jp @taktopia.com @lne.st .yomiuri.com @yomiuri.com])
  end
end
