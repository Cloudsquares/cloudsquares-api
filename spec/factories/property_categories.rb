FactoryBot.define do
  factory :property_category do
    association :agency
    sequence(:title) { |n| "Category #{n}" }
    sequence(:slug) { |n| "category-#{n}" }
    level { 0 }
    parent_id { nil }
    is_active { true }
    position { 0 }

    trait :subcategory do
      level { 1 }
      association :parent, factory: :property_category
    end

    trait :inactive do
      is_active { false }
    end
  end
end
