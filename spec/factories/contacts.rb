FactoryBot.define do
  factory :contact do
    association :agency
    association :person
    sequence(:first_name) { |n| "Contact#{n}" }
    last_name { "Test" }
    middle_name { nil }
    sequence(:email) { |n| "contact#{n}@example.com" }
    notes { nil }
    extra_phones { [] }
    is_deleted { false }

    trait :deleted do
      is_deleted { true }
      deleted_at { Time.current }
    end

    trait :with_extra_phones do
      extra_phones { ["77001112233", "77004445566"] }
    end

    trait :with_notes do
      notes { "Important contact notes" }
    end
  end
end
