FactoryBot.define do
  factory :property_location do
    association :property
    country { "Russia" }
    region { "Moscow Oblast" }
    city { "Moscow" }
    street { "Test Street" }
    house_number { "1" }
    map_link { nil }
    is_info_hidden { false }

    trait :hidden do
      is_info_hidden { true }
    end

    trait :with_map do
      map_link { "https://maps.google.com/?q=55.7558,37.6173" }
    end

    trait :kazakhstan do
      country { "Kazakhstan" }
      region { "Almaty Oblast" }
      city { "Almaty" }
    end
  end
end
