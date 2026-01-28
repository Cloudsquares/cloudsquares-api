FactoryBot.define do
  factory :user do
    association :person
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "SecurePassword1!" }
    password_confirmation { "SecurePassword1!" }
    country_code { "RU" }
    role { :user }
    user_status { :active }

    trait :admin do
      role { :admin }
    end

    trait :admin_manager do
      role { :admin_manager }
    end

    trait :agent_admin do
      role { :agent_admin }
    end

    trait :agent_manager do
      role { :agent_manager }
    end

    trait :agent do
      role { :agent }
    end

    trait :inactive do
      user_status { :deactivated }
    end

    trait :with_agency do
      after(:create) do |user|
        plan = AgencyPlan.find_by(is_default: true) || create(:agency_plan, :default)
        agency = create(:agency, agency_plan: plan, created_by: user)
        create(:user_agency, user: user, agency: agency, is_default: true, status: :active)
      end
    end
  end
end
