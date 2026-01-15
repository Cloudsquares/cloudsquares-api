# frozen_string_literal: true

# Модель пользователя.
# Пользователь 1:1 связан с Person (глобальная личность по телефону).
# Телефона/ФИО в таблице users больше нет — телефон живёт в person.normalized_phone,
# ФИО/прочие агентские данные — в Contact внутри конкретного агентства.
#
# Аутентификация: по паре (телефон -> person -> user) + пароль (has_secure_password).
class User < ApplicationRecord
  # Пароль через bcrypt
  has_secure_password

  # Связи
  belongs_to :person
  belongs_to :status_changed_by, class_name: "User", optional: true

  has_many :user_agencies, dependent: :restrict_with_error
  has_many :agencies, through: :user_agencies
  has_many :property_comments, dependent: :nullify
  has_many :property_buy_requests, dependent: :nullify

  has_one  :profile, class_name: "UserProfile", dependent: :destroy
  after_create :ensure_profile!

  # Текущие доступные регионы
  VALID_COUNTRY_CODES = %w[RU KZ BY].freeze

  # Роли
  enum :role, {
    admin: 0,
    admin_manager: 1,
    agent_admin: 2,
    agent_manager: 3,
    agent: 4,
    user: 5
  }, default: :user

  # Статусы пользователя
  # NOTE: статус хранится строкой для масштабируемости.
  USER_STATUSES = {
    active: "active",
    banned: "banned",
    pending: "pending",
    verification_required: "verification_required",
    deactivated: "deactivated"
  }.freeze

  enum :user_status, USER_STATUSES, default: :active

  # Валидации
  validates :person_id, presence: true
  validates :country_code, inclusion: { in: VALID_COUNTRY_CODES }
  validates :user_status, inclusion: { in: user_statuses.keys }
  # email в users оставляем опциональным (в планах — email только как контактная инфа)
  validates :email, uniqueness: true, allow_nil: true
  validates :password_digest, presence: true

  validate :validate_password_complexity, if: -> { password.present? }

  before_validation :set_default_status_audit, on: :create

  # Возвращает агентство по умолчанию
  def default_agency
    user_agencies.find_by(is_default: true)&.agency
  end

  # Проверяет, допускается ли авторизация пользователя.
  #
  # @return [Boolean]
  def can_authenticate?
    return false if banned? || deactivated?

    # TODO: определить правила доступа для pending и verification_required.
    true
  end

  # Обновляет статус пользователя с аудитом.
  #
  # @param status [String, Symbol]
  # @param description [String, nil]
  # @param changed_by [User, nil]
  # @return [Boolean]
  def update_status!(status:, description:, changed_by: nil)
    assign_attributes(
      user_status: status,
      user_status_description: description,
      status_changed_at: Time.zone.now,
      status_changed_by_id: changed_by&.id
    )
    save!
  end

  def ensure_profile!
    profile || build_profile(timezone: "UTC", locale: I18n.default_locale.to_s).save!
  end

  private

  # Устанавливает дату смены статуса при первичном создании пользователя.
  #
  # @return [void]
  def set_default_status_audit
    self.status_changed_at ||= Time.zone.now
  end

  # Строгая проверка сложности пароля (минимум 12, верхний/нижний регистр, цифра, спецсимвол)
  def validate_password_complexity
    errors.add(:password, "должен содержать минимум 12 символов") unless password.length >= 12
    errors.add(:password, "должен содержать хотя бы одну заглавную букву A-Z") unless password.match?(/[A-Z]/)
    errors.add(:password, "должен содержать хотя бы одну строчную букву a-z") unless password.match?(/[a-z]/)
    errors.add(:password, "должен содержать хотя бы одну цифру") unless password.match?(/\d/)
    errors.add(:password, "должен содержать хотя бы один специальный символ") unless password.match?(/^.*(?=.*[!*@#$%^&+=_-]).*$/)
  end
end
