FactoryBot.define do
  factory :agency do
    sequence(:title) { |n| "Agency #{n}" }
    sequence(:slug) { |n| "agency-#{n}" }
    custom_domain { nil }
    is_blocked { false }
    is_active { true }
    association :agency_plan
    association :created_by, factory: :user

    trait :blocked do
      is_blocked { true }
      blocked_at { Time.current }
    end

    trait :inactive do
      is_active { false }
      deleted_at { Time.current }
    end

    trait :with_custom_domain do
      sequence(:custom_domain) { |n| "agency#{n}.example.com" }
    end

    after(:create) do |agency|
      # Ensure agency setting is created
      agency.agency_setting || create(:agency_setting, agency: agency)
    end
  end
end
