FactoryBot.define do
  factory :agency_setting do
    association :agency, create_agency_setting: false
    site_title { "Test Agency Site" }
    site_description { "Agency description" }
    home_page_content { "" }
    contacts_page_content { "" }
    meta_keywords { "" }
    meta_description { "" }
    color_scheme { "default" }
    logo_url { nil }
    locale { "ru" }
    timezone { "Europe/Moscow" }

    trait :with_logo do
      logo_url { "https://example.com/logo.png" }
    end

    trait :english do
      locale { "en" }
    end

    trait :kazakh do
      locale { "kz" }
      timezone { "Asia/Almaty" }
    end
  end
end
