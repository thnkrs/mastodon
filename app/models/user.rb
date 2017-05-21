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

  scope :recent,    -> { order('id desc') }
  scope :admins,    -> { where(admin: true) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }

  def must_be_teenager
    return true if age >= 10 && age < 20

    errors.add(:base, 'Facebookで登録するには10代である必要があります。')
  end

  def age
    raise "Birthday is not given to the user: #{account.username}" if birthday.blank?

    now = Date.today
    now.year - birthday.year
      ((birthday.month > now.month || (birthday.month == now.month && birthday.day > now.day)) ? 0 : 1)
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
    user = joins(:credential).where(credentials: { provider: auth.provider, uid: auth.uid }).first
    if user
      user.credential.update \
        provider: auth.provider,
        uid: auth.uid,
        token: auth.credentials.token,
        expires_at: Time.at(auth.credentials.expires_at)

      return user
    end

    password = Devise.friendly_token[0, 20]
    user = User.new \
      email: auth.info.email,
      password: password,
      password_confirmation: password

    if user.credential.blank?
      user.build_credential \
        provider: auth.provider,
        uid: auth.uid,
        token: auth.credentials.token,
        expires_at: Time.at(auth.credentials.expires_at)
    end

    birthday = Koala::Facebook::API.new(user.credential.token).get_object('me', fields: 'birthday')['birthday']
    user.birthday = Date.strptime(birthday, '%M/%d/%Y')

    if user.account.blank?
      user.build_account
      user.account.username = auth.extra.raw_info.username

      # TODO: 登録時ユーザーが指定できるようにする
      if auth.extra.raw_info.username
        user.account.username = username
      else
        username = user.email.split('@').first
        user.account.username = username.gsub(/[^a-z0-9_]/, '')
      end
      user.account.display_name = auth.info.name
    end

    user.skip_confirmation!
    user.save
    user
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session['devise.facebook_data'] && data['info']['email']
        user.email = data['info']['email']
      end
    end
  end
end
