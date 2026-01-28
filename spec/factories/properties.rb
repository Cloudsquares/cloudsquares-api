FactoryBot.define do
  factory :property do
    association :agency
    association :agent, factory: :user
    association :category, factory: :property_category
    sequence(:title) { |n| "Property #{n}" }
    description { "Test property description" }
    price { 1_000_000.00 }
    discount { 0.0 }
    listing_type { :sale }
    status { :pending }
    is_active { true }

    trait :for_rent do
      listing_type { :rent }
      price { 50_000.00 }
    end

    trait :active do
      status { :active }
    end

    trait :sold do
      status { :sold }
    end

    trait :rented do
      status { :rented }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :with_discount do
      discount { 100_000.00 }
    end

    trait :inactive do
      is_active { false }
      deleted_at { Time.current }
    end

    trait :with_location do
      after(:create) do |property|
        create(:property_location, property: property)
      end
    end

    trait :with_photos do
      after(:create) do |property|
        create_list(:property_photo, 3, property: property)
      end
    end

    trait :complete do
      with_location
      with_photos
      status { :active }
    end
  end
end
