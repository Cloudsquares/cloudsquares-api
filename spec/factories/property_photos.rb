FactoryBot.define do
  factory :property_photo do
    association :property
    sequence(:file_url) { |n| "https://example.com/photos/photo#{n}.jpg" }
    is_main { false }
    sequence(:position) { |n| n }
    access { "public" }

    trait :main do
      is_main { true }
      position { 0 }
    end

    trait :private do
      access { "private" }
    end
  end
end
