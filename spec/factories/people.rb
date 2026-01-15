FactoryBot.define do
  factory :person do
    sequence(:normalized_phone) { |n| "7700#{format('%07d', n)}" }
    is_active { true }
  end
end
