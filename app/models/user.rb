# frozen_string_literal: true

class User < ApplicationRecord
  include Settings::Extend

  devise :registerable, :recoverable,
         :rememberable, :trackable, :validatable, :confirmable,
         :two_factor_authenticatable, :two_factor_backupable,
         otp_secret_encryption_key: ENV['OTP_SECRET'],
         otp_number_of_backup_codes: 10

  devise :omniauthable, omniauth_providers: [:facebook]

  belongs_to :account, inverse_of: :user, required: true
  has_one :credential
  accepts_nested_attributes_for :account

  validates :locale, inclusion: I18n.available_locales.map(&:to_s), unless: 'locale.nil?'
  validates :email, email: true

  validate :must_be_teenager, if: -> { birthday.present? }
  validates :birthday, presence: true, if: :facebook_login?

  scope :recent,    -> { order('id desc') }
  scope :admins,    -> { where(admin: true) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }

  def must_be_teenager
    errors.add(:base, 'Facebookで登録するには10代である必要があります。') unless teenager?
  end

  def teenager?
    return false if birthday.blank?
    age >= 10 && age < 20
  end

  def age
    raise "Birthday is not given to the user: #{account.username}" if birthday.blank?

    now = Date.today
    now.year - birthday.year \
      - ((birthday.month > now.month || (birthday.month == now.month && birthday.day > now.day)) ? 0 : 1)
  end

  def confirmed?
    confirmed_at.present?
  end

  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end

  def setting_default_privacy
    settings.default_privacy || (account.locked? ? 'private' : 'public')
  end

  def setting_boost_modal
    settings.boost_modal
  end

  def setting_auto_play_gif
    settings.auto_play_gif
  end

  def self.from_omniauth(auth)
    # jsonにキャッシュしたもので来る場合と、生で来る場合があるので正規化
    auth = auth.as_json.with_indifferent_access

    provider = auth[:provider]
    uid = auth[:uid]
    credentials_token = auth.dig(:credentials, :token)
    credentials_expires_at = Time.at auth.dig(:credentials, :expires_at)
    profile_link = auth.dig(:extra, :raw_info, :link)

    credential_params = {
      provider: provider,
      uid: uid,
      token: credentials_token,
      expires_at: credentials_expires_at,
      link: profile_link
    }

    user = joins(:credential).where(credentials: { provider: provider, uid: uid }).first
    if user
      user.credential.update credential_params
      return user
    end

    email = auth.dig(:info, :email)
    password = Devise.friendly_token[0, 20]
    user = User.new \
      email: email,
      password: password,
      password_confirmation: password

    user.build_credential credential_params if user.credential.blank?

    user.build_account if user.account.blank?

    user
  end

  def load_facebook_birthday
    fail 'birthday only supports Facebook' unless facebook_login?
    birthday = Koala::Facebook::API.new(self.credential.token).get_object('me', fields: 'birthday')['birthday']
    self.birthday = Date.strptime(birthday, '%M/%d/%Y') if birthday.present?
  rescue Koala::KoalaError
    self.birthday = nil
  ensure
    self.birthday
  end

  def facebook_login?
    self.credential.try!(:provider) == 'facebook'
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session['devise.facebook_data'] && data['info']['email']
        user.email = data['info']['email']
      end
    end
  end
end
