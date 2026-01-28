FactoryBot.define do
  factory :customer do
    association :agency
    association :contact
    user { nil }
    service_type { :buy }
    notes { nil }
    is_active { true }

    trait :seller do
      service_type { :sell }
    end

    trait :renter do
      service_type { :rent_in }
    end

    trait :landlord do
      service_type { :rent_out }
    end

    trait :other do
      service_type { :other }
    end

    trait :with_user do
      association :user
    end

    trait :with_notes do
      notes { "Customer notes" }
    end

    trait :inactive do
      is_active { false }
    end
  end
end
