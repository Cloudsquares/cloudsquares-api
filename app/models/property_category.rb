# frozen_string_literal: true

# Модель категории недвижимости.
#
# Особенности:
# - Слаг генерируется через FriendlyId + Shared::HasFriendlySlug из title.
# - Уникальность слуга «в рамках агентства» (scope: :agency_id).
# - Максимум один уровень вложенности (уровни: 0 — корень, 1 — подкатегория).
#
class PropertyCategory < ApplicationRecord
  include Shared::HasFriendlySlug
  has_friendly_slug source: :title, scope: :agency_id, fallback: "item"

  belongs_to :agency
  belongs_to :parent, class_name: "PropertyCategory", optional: true
  has_many   :children, class_name: "PropertyCategory", foreign_key: :parent_id, dependent: :destroy

  has_many :property_category_characteristics, dependent: :destroy
  has_many :property_characteristics, through: :property_category_characteristics
  # has_many :properties, dependent: :restrict_with_error

  # Базовые проверки
  validates :title, presence: true
  validates :slug,  presence: true, uniqueness: { scope: :agency_id, case_sensitive: false }
  validates :level, inclusion: { in: [0, 1] }
  validate  :validate_max_depth

  scope :active, -> { where(is_active: true) }
  scope :roots,  -> { where(parent_id: nil) }

  # Нормализация/вычисления до валидации
  before_validation :normalize_parent_id
  before_validation :assign_level

  before_destroy :check_dependencies

  private

  # Приводим пустую строку к nil (иначе будет считаться дочерней)
  def normalize_parent_id
    self.parent_id = nil if parent_id.blank?
  end

  # Уровень: 0 — корневая, 1 — подкатегория
  def assign_level
    self.level = parent_id.nil? ? 0 : 1
  end

  # Нельзя удалять, если есть дочерние
  def check_dependencies
    if children.exists?
      errors.add(:base, "Нельзя удалить категорию с подкатегориями")
      throw :abort
    end
  end

  # Ограничение глубины
  def validate_max_depth
    if parent&.parent.present?
      errors.add(:parent_id, "допустима вложенность только до одного уровня")
    end
  end
end
