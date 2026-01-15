FactoryBot.define do
  factory :user_agency do
    association :user
    association :agency
    is_default { false }
    status { :active }

    trait :default do
      is_default { true }
    end

    trait :pending do
      status { :pending }
    end

    trait :inactive do
      status { :inactive }
    end
  end
end
