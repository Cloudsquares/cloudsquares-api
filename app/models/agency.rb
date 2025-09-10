# frozen_string_literal: true

# Модель агентства недвижимости в CloudSquares.
# Агентство обязано принадлежать тарифному плану (agency_plan) — это важная бизнес-инварианта.
#
# Коллбеки:
# - after_create :create_agency_setting! — создаёт настройки публичной платформы.
# - after_create :seed_default_data!    — наполняет базовыми справочниками (идемпотентно).
#
# Валидации:
# - title, slug — обязательны; slug уникален в системе (используется для URL/субдомена).
# - custom_domain — уникален, но может отсутствовать.
#
# Генерация slug:
# - Используем общий механизм FriendlyId + Shared::SlugNormalizer (Babosa + fallback).
# - По умолчанию slug генерируется из title; если slug передан вручную — он будет
#   нормализован и оставлен как есть (мы уважаем ручной slug).
class Agency < ApplicationRecord
  # ===== Slug / FriendlyId ====================================================
  include Shared::HasFriendlySlug
  # Без скоупа: уникальность slug глобально в системе.
  has_friendly_slug source: :title

  # Если хотим уважать вручную присланный slug и НЕ перегенерировать его из title,
  # переопределяем поведение FriendlyId: генерировать только когда slug пустой.
  def should_generate_new_friendly_id?
    slug.blank?
  end

  # Если slug пришёл вручную, нормализуем его тем же правилом, что и FriendlyId.
  before_validation :normalize_manual_slug

  # ===== Ассоциации ===========================================================
  has_one :agency_setting, dependent: :destroy
  has_many :property_categories, dependent: :destroy
  has_many :property_characteristics, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :property_buy_requests, dependent: :nullify

  has_many :user_agencies, dependent: :destroy
  has_many :users, through: :user_agencies, dependent: :restrict_with_error

  # Доменные сущности (когда будут готовы):
  has_many :properties, dependent: :restrict_with_error
  # has_many :buy_requests,  dependent: :restrict_with_error
  # has_many :sell_requests, dependent: :restrict_with_error

  # Важно: одна декларация belongs_to :agency_plan (ассоциация обязательна)
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :agency_plan

  # ===== Коллбеки доменной логики =============================================
  after_create :create_agency_setting!
  after_create :seed_default_data!

  # ===== Валидации =============================================================
  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :custom_domain, uniqueness: true, allow_blank: true

  # ===== Скоупы ================================================================
  scope :active, -> { where(is_blocked: false) }

  # ===== Публичные методы ======================================================
  # Поиск агентства по домену (для публичной платформы)
  def self.find_by_request_host(host)
    find_by!(custom_domain: host)
  end

  # Мягкое удаление
  def soft_delete!
    update(is_active: false, deleted_at: Time.zone.now)
  end

  private

  # Нормализация ручного slug (если он пришёл в params)
  def normalize_manual_slug
    return if slug.blank?

    self.slug = Shared::SlugNormalizer.normalize(slug, fallback: "agency")
  end

  # Создаём настройки публичной платформы сразу после создания агентства
  def create_agency_setting!
    build_agency_setting(
      site_title: "Недвижимость от #{title}",
      locale:     "ru",
      timezone:   "Europe/Moscow"
    ).save!
  end

  # Наполняем базовыми сущностями (категории, характеристики и т.д.)
  def seed_default_data!
    Agencies::TemplateSeeder.new(self).call
  end
end
