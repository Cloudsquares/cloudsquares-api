# frozen_string_literal: true

# Политика доступа к владельцам недвижимости (PropertyOwner).
#
# Правила:
# - index? — сотрудники видят владельцев в рамках ТЕКУЩЕГО агентства.
# - show?/update?/destroy?/create? — только в рамках того же агентства (по property.agency_id).
#
# Поддерживает авторизацию как по классу (authorize PropertyOwner), так и по записи
# (authorize @owner). Для class-level проверяем только право управления и наличие текущего агентства.
class PropertyOwnerPolicy < ApplicationPolicy
  # Список владельцев для конкретного объекта / агентства
  #
  # @return [Boolean]
  def index?
    manage? && Current.agency.present?
  end

  # Просмотр владельца
  #
  # @return [Boolean]
  def show?
    can_manage_same_agency_record?
  end

  # Создание владельца
  #
  # @return [Boolean]
  def create?
    if record.is_a?(Class)
      # class-level authorize (например, ранние валидации в контроллере)
      manage? && Current.agency.present?
    else
      can_manage_same_agency_record?
    end
  end

  # Обновление владельца
  #
  # @return [Boolean]
  def update?
    can_manage_same_agency_record?
  end

  # Мягкое удаление владельца
  #
  # @return [Boolean]
  def destroy?
    can_manage_same_agency_record?
  end

  # Scope: владельцы в рамках текущего агентства
  class Scope < Scope
    # @return [ActiveRecord::Relation]
    def resolve
      return scope.none unless Current.agency
      return scope.joins(:property).where(properties: { agency_id: Current.agency.id }) if admin? || admin_manager? || agent_admin? || agent_manager? || agent?

      scope.none
    end
  end

  private

  # Общая проверка: право управлять + принадлежность записи текущему агентству
  #
  # @return [Boolean]
  def can_manage_same_agency_record?
    return false unless manage?
    same_agency?
  end

  # Совпадает ли агентство объекта владельца с текущим агентством контекста
  #
  # @return [Boolean]
  def same_agency?
    return false unless Current.agency
    return false unless record.respond_to?(:property)

    property = record.property
    property && property.agency_id == Current.agency.id
  end
end
