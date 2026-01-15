FactoryBot.define do
  factory :agency_plan do
    sequence(:title) { |n| "Plan #{n}" }
    description { "Test plan description" }
    max_employees { 10 }
    max_properties { 100 }
    max_photos { 20 }
    max_buy_requests { 500 }
    max_sell_requests { 500 }
    is_custom { false }
    is_active { true }
    is_default { false }

    trait :default do
      title { "Default Plan" }
      is_default { true }
    end

    trait :custom do
      is_custom { true }
    end

    trait :inactive do
      is_active { false }
    end

    trait :starter do
      title { "Starter" }
      max_employees { 3 }
      max_properties { 20 }
      max_photos { 10 }
    end

    trait :professional do
      title { "Professional" }
      max_employees { 15 }
      max_properties { 200 }
      max_photos { 30 }
    end
  end
end
