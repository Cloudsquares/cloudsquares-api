# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.swagger_docs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "CloudSquares API",
        version: "v1",
        description: "Real estate agency management platform API",
        contact: {
          email: "support@cloudsquares.com"
        }
      },
      servers: [
        { url: "http://localhost:3001", description: "Development" },
        { url: "https://api.cloudsquares.com", description: "Production" }
      ],
      tags: [
        { name: "Authentication", description: "JWT-based authentication endpoints" },
        { name: "Users", description: "User management and profile operations" },
        { name: "Agencies", description: "Real estate agency CRUD operations" },
        { name: "Agency Plans", description: "Subscription plan management" },
        { name: "Agency Settings", description: "Agency configuration" },
        { name: "Properties", description: "Property listings management" },
        { name: "Property Categories", description: "Property classification" },
        { name: "Property Characteristics", description: "Property attributes" },
        { name: "Property Owners", description: "Property ownership records" },
        { name: "Property Comments", description: "Internal property notes" },
        { name: "Property Buy Requests", description: "Purchase inquiries" },
        { name: "Customers", description: "Customer/client management" },
        { name: "Contacts", description: "Contact directory" },
        { name: "Internal", description: "Internal service endpoints" }
      ],
      components: {
        securitySchemes: {
          Bearer: {
            type: :http,
            scheme: :bearer,
            bearerFormat: :JWT,
            description: "JWT access token (15 min TTL). Obtain via /api/v1/auth/login"
          }
        },
        schemas: {
          # === Common Types ===
          UUID: {
            type: :string,
            format: :uuid,
            example: "550e8400-e29b-41d4-a716-446655440000"
          },

          Phone: {
            type: :string,
            pattern: '^\d{10,15}$',
            description: "Normalized phone number (digits only, 10-15 chars)",
            example: "77001234567"
          },

          Email: {
            type: :string,
            format: :email,
            example: "user@example.com"
          },

          Timestamp: {
            type: :string,
            format: "date-time",
            example: "2024-01-15T10:30:00Z"
          },

          # === Error Responses ===
          Error: {
            type: :object,
            properties: {
              error: {
                type: :object,
                properties: {
                  key: { type: :string, example: "auth.invalid_credentials" },
                  message: {
                    oneOf: [
                      { type: :string, example: "Invalid login or password" },
                      {
                        type: :object,
                        properties: {
                          key: { type: :string },
                          message: { type: :string }
                        }
                      }
                    ]
                  },
                  code: { type: :integer, example: 401 },
                  status: { type: :string, example: "unauthorized" }
                },
                required: %w[key code]
              }
            },
            required: %w[error]
          },

          ValidationError: {
            type: :object,
            properties: {
              error: {
                type: :object,
                properties: {
                  key: { type: :string, example: "validation.failed" },
                  message: { type: :string, example: "Validation failed" },
                  code: { type: :integer, example: 422 },
                  status: { type: :string, example: "unprocessable_entity" },
                  details: {
                    type: :object,
                    additionalProperties: {
                      type: :array,
                      items: { type: :string }
                    },
                    example: { email: [ "is invalid" ], password: [ "is too short" ] }
                  }
                }
              }
            }
          },

          SuccessMessage: {
            type: :object,
            properties: {
              success: {
                type: :object,
                properties: {
                  key: { type: :string, example: "auth.logout" },
                  message: { type: :string, example: "Logged out successfully" },
                  code: { type: :integer, example: 200 },
                  status: { type: :string, example: "ok" }
                }
              }
            }
          },

          # === Pagination ===
          PaginationMeta: {
            type: :object,
            properties: {
              current_page: { type: :integer, example: 1 },
              total_pages: { type: :integer, example: 5 },
              total_count: { type: :integer, example: 100 },
              per_page: { type: :integer, example: 20 }
            }
          },

          # === Auth Schemas ===
          AuthTokens: {
            type: :object,
            properties: {
              access_token: { type: :string, description: "JWT access token (15 min TTL)" },
              refresh_token: { type: :string, description: "JWT refresh token (14 days TTL)" },
              expires_in: { type: :integer, description: "Token issue timestamp (epoch)" }
            },
            required: %w[access_token refresh_token]
          },

          LoginRequest: {
            type: :object,
            properties: {
              phone: { "$ref": "#/components/schemas/Phone" },
              password: { type: :string, minLength: 12, description: "Min 12 chars, upper/lower/digit/special" },
              agency_id: { "$ref": "#/components/schemas/UUID" },
              property_id: { "$ref": "#/components/schemas/UUID" }
            },
            required: %w[phone password],
            example: { phone: "77001234567", password: "SecurePassword1!" }
          },

          RefreshRequest: {
            type: :object,
            properties: {
              refresh_token: { type: :string, description: "Valid refresh token" },
              agency_id: { "$ref": "#/components/schemas/UUID" }
            },
            required: %w[refresh_token]
          },

          # === Enums ===
          UserRole: {
            type: :string,
            enum: %w[admin admin_manager agent_admin agent_manager agent user],
            description: "User role: admin (super), admin_manager, agent_admin (agency owner), agent_manager, agent, user (B2C)"
          },

          CountryCode: {
            type: :string,
            enum: %w[RU KZ BY],
            description: "Supported country codes"
          },

          ListingType: {
            type: :string,
            enum: %w[sale rent],
            description: "Property listing type"
          },

          PropertyStatus: {
            type: :string,
            enum: %w[pending active sold rented cancelled],
            description: "Property status: pending (draft), active (published), sold, rented, cancelled"
          },

          OwnerRole: {
            type: :string,
            enum: %w[primary partner relative other],
            description: "Property owner role"
          },

          ServiceType: {
            type: :string,
            enum: %w[buy sell rent_in rent_out other],
            description: "Customer service type"
          },

          BuyRequestStatus: {
            type: :string,
            enum: %w[pending viewed processed rejected],
            description: "Buy request processing status"
          },

          CharacteristicFieldType: {
            type: :string,
            enum: %w[string text number boolean select],
            description: "Property characteristic field type"
          },

          # === User Schemas ===
          User: {
            type: :object,
            properties: {
              id: { "$ref": "#/components/schemas/UUID" },
              phone: { "$ref": "#/components/schemas/Phone" },
              email: { "$ref": "#/components/schemas/Email" },
              role: { "$ref": "#/components/schemas/UserRole" },
              country_code: { "$ref": "#/components/schemas/CountryCode" },
              is_active: { type: :boolean },
              first_name: { type: :string, nullable: true },
              last_name: { type: :string, nullable: true },
              middle_name: { type: :string, nullable: true },
              timezone: { type: :string, example: "Europe/Moscow" },
              locale: { type: :string, example: "ru" },
              avatar_url: { type: :string, nullable: true },
              agency: {
                oneOf: [
                  { "$ref": "#/components/schemas/AgencyCompact" },
                  { type: :null }
                ],
                nullable: true
              },
              deleted_at: { "$ref": "#/components/schemas/Timestamp" }
            },
            required: %w[id phone role country_code is_active]
          },

          UserCreateRequest: {
            type: :object,
            properties: {
              user: {
                type: :object,
                properties: {
                  phone: { "$ref": "#/components/schemas/Phone" },
                  email: { "$ref": "#/components/schemas/Email" },
                  password: { type: :string, minLength: 12 },
                  password_confirmation: { type: :string },
                  role: { "$ref": "#/components/schemas/UserRole" },
                  country_code: { "$ref": "#/components/schemas/CountryCode" },
                  first_name: { type: :string },
                  last_name: { type: :string },
                  middle_name: { type: :string },
                  timezone: { type: :string },
                  locale: { type: :string }
                },
                required: %w[phone password password_confirmation role country_code]
              }
            },
            required: %w[user]
          },

          UserUpdateRequest: {
            type: :object,
            properties: {
              user: {
                type: :object,
                properties: {
                  first_name: { type: :string },
                  last_name: { type: :string },
                  middle_name: { type: :string },
                  timezone: { type: :string },
                  locale: { type: :string },
                  avatar_url: { type: :string },
                  email: { "$ref": "#/components/schemas/Email" },
                  password: { type: :string, minLength: 12 },
                  password_confirmation: { type: :string },
                  current_password: { type: :string, description: "Required when changing password" },
                  notification_prefs: { type: :object },
                  ui_prefs: { type: :object }
                }
              }
            }
          },

          # === Agency Schemas ===
          AgencyCompact: {
            type: :object,
            properties: {
              id: { "$ref": "#/components/schemas/UUID" },
              title: { type: :string },
              slug: { type: :string },
              custom_domain: { type: :string, nullable: true }
            }
          },

          Agency: {
            type: :object,
            properties: {
              id: { "$ref": "#/components/schemas/UUID" },
              title: { type: :string, example: "Premium Realty" },
              slug: { type: :string, example: "premium-realty" },
              custom_domain: { type: :string, nullable: true },
              is_blocked: { type: :boolean },
              blocked_at: { "$ref": "#/components/schemas/Timestamp" },
              is_active: { type: :boolean },
              deleted_at: { "$ref": "#/components/schemas/Timestamp" },
              created_at: { "$ref": "#/components/schemas/Timestamp" },
              updated_at: { "$ref": "#/components/schemas/Timestamp" },
              agency_setting: { "$ref": "#/components/schemas/AgencySetting" },
              agency_plan: { "$ref": "#/components/schemas/AgencyPlan" }
            },
            required: %w[id title slug is_active]
          },

          AgencyCreateRequest: {
            type: :object,
            properties: {
              agency: {
                type: :object,
                properties: {
                  title: { type: :string },
                  slug: { type: :string, description: "Auto-generated from title if not provided" },
                  custom_domain: { type: :string },
                  agency_plan_id: { "$ref": "#/components/schemas/UUID" }
                },
                required: %w[title]
              }
            },
            required: %w[agency]
          },

          AgencyPlan: {
            type: :object,
            properties: {
              id: { "$ref": "#/components/schemas/UUID" },
              title: { type: :string, example: "Professional" },
              description: { type: :string },
              max_employees: { type: :integer, example: 10 },
              max_properties: { type: :integer, example: 100 },
              max_photos: { type: :integer, example: 20 },
              max_buy_requests: { type: :integer, example: 500 },
              max_sell_requests: { type: :integer, example: 500 },
              is_custom: { type: :boolean },
              is_active: { type: :boolean },
              is_default: { type: :boolean },
              created_at: { "$ref": "#/components/schemas/Timestamp" },
              updated_at: { "$ref": "#/components/schemas/Timestamp" }
            }
          },

          AgencyPlanCreateRequest: {
            type: :object,
            properties: {
              agency_plan: {
                type: :object,
                properties: {
                  title: { type: :string },
                  description: { type: :string },
                  max_employees: { type: :integer },
                  max_properties: { type: :integer },
                  max_photos: { type: :integer },
                  max_buy_requests: { type: :integer },
                  max_sell_requests: { type: :integer }
                },
                required: %w[title max_employees max_properties max_photos]
              }
            },
            required: %w[agency_plan]
          },

          AgencySetting: {
            type: :object,
            properties: {
              id: { "$ref": "#/components/schemas/UUID" },
              site_title: { type: :string },
              site_description: { type: :string },
              home_page_content: { type: :string },
              contacts_page_content: { type: :string },
              meta_keywords: { type: :string },
              meta_description: { type: :string },
              color_scheme: { type: :string },
              logo_url: { type: :string },
              locale: { type: :string, example: "ru" },
              timezone: { type: :string, example: "Europe/Moscow" },
              translations: { type: :object, description: "i18n translations for all locales" },
              created_at: { "$ref": "#/components/schemas/Timestamp" },
              updated_at: { "$ref": "#/components/schemas/Timestamp" }
            }
          },

          AgencySettingUpdateRequest: {
            type: :object,
            properties: {
              agency_setting: {
                type: :object,
                properties: {
                  site_title: { type: :string },
                  site_description: { type: :string },
                  color_scheme: { type: :string },
                  logo_url: { type: :string },
                  locale: { type: :string },
                  timezone: { type: :string },
                  home_page_content: { type: :string },
                  contacts_page_content: { type: :string },
                  meta_keywords: { type: :string },
                  meta_description: { type: :string }
                }
              }
            }
          },

          # === Property Schemas ===
          Property: {
            type: :object,
            properties: {
              id: { "$ref": "#/components/schemas/UUID" },
              title: { type: :string, example: "3-room apartment in city center" },
              slug: { type: :string },
              description: { type: :string, description: "HTML content (TipTap editor)" },
              price: { type: :number, format: :float, minimum: 0 },
              discount: { type: :number, format: :float, minimum: 0, default: 0 },
              listing_type: { "$ref": "#/components/schemas/ListingType" },
              status: { "$ref": "#/components/schemas/PropertyStatus" },
              is_active: { type: :boolean },
              characteristics: {
                type: :array,
                items: { "$ref": "#/components/schemas/PropertyCharacteristicValue" }
              },
              category: { "$ref": "#/components/schemas/PropertyCategory" },
              agent: { "$ref": "#/components/schemas/AgentCompact" },
              agency: { "$ref": "#/components/schemas/AgencyCompact" },
              property_location: { "$ref": "#/components/schemas/PropertyLocation" },
              property_photos: {
                type: :array,
                items: { "$ref": "#/components/schemas/PropertyPhoto" }
              },
              property_owners: {
                type: :array,
                items: { "$ref": "#/components/schemas/PropertyOwner" },
                description: "Only visible to agency members"
              },
              created_at: { "$ref": "#/components/schemas/Timestamp" },
              updated_at: { "$ref": "#/components/schemas/Timestamp" }
            },
            required: %w[id title price listing_type status]
          },

          PropertyCreateRequest: {
            type: :object,
            properties: {
              property: {
                type: :object,
                properties: {
                  title: { type: :string },
                  description: { type: :string, maxLength: 50000 },
                  price: { type: :number, minimum: 0 },
                  discount: { type: :number, minimum: 0 },
                  listing_type: { "$ref": "#/components/schemas/ListingType" },
                  status: { "$ref": "#/components/schemas/PropertyStatus" },
                  category_id: { "$ref": "#/components/schemas/UUID" },
                  property_location_attributes: { "$ref": "#/components/schemas/PropertyLocationInput" },
                  property_characteristic_values_attributes: {
                    type: :array,
                    items: {
                      type: :object,
                      properties: {
                        property_characteristic_id: { "$ref": "#/components/schemas/UUID" },
                        value: { type: :string }
                      }
                    }
                  }
                },
                required: %w[title price listing_type category_id]
              }
            },
            required: %w[property]
          },

          PropertyLocation: {
            type: :object,
            properties: {
              id: { "$ref": "#/components/schemas/UUID" },
              country: { type: :string },
              region: { type: :string },
              city: { type: :string },
              street: { type: :string },
              house_number: { type: :string },
              map_link: { type: :string },
              is_info_hidden: { type: :boolean },
              geo_city_id: { type: :string }
            }
          },

          PropertyLocationInput: {
            type: :object,
            properties: {
              country: { type: :string },
              region: { type: :string },
              city: { type: :string },
              street: { type: :string },
              house_number: { type: :string },
              map_link: { type: :string },
              is_info_hidden: { type: :boolean }
            },
            description: "Required for activating property: country, region, city, street"
          },

          PropertyPhoto: {
            type: :object,
            properties: {
              id: { "$ref": "#/components/schemas/UUID" },
              file_url: { type: :string },
              file_preview_url: { type: :string },
              file_retina_url: { type: :string },
              is_main: { type: :boolean },
              position: { type: :integer },
              access: { type: :string },
              created_at: { "$ref": "#/components/schemas/Timestamp" }
            }
          },

          PropertyCategory: {
            type: :object,
            properties: {
              id: { "$ref": "#/components/schemas/UUID" },
              title: { type: :string },
              slug: { type: :string },
              level: { type: :integer, description: "0 = parent, 1 = subcategory" },
              parent_id: { "$ref": "#/components/schemas/UUID" },
              is_active: { type: :boolean },
              position: { type: :integer },
              created_at: { "$ref": "#/components/schemas/Timestamp" },
              updated_at: { "$ref": "#/components/schemas/Timestamp" }
            }
          },

          PropertyCategoryCreateRequest: {
            type: :object,
            properties: {
              property_category: {
                type: :object,
                properties: {
                  title: { type: :string },
                  position: { type: :integer },
                  parent_id: { "$ref": "#/components/schemas/UUID" },
                  is_active: { type: :boolean }
                },
                required: %w[title]
              }
            },
            required: %w[property_category]
          },

          PropertyCharacteristic: {
            type: :object,
            properties: {
              id: { "$ref": "#/components/schemas/UUID" },
              title: { type: :string },
              unit: { type: :string, nullable: true, example: "m2" },
              field_type: { "$ref": "#/components/schemas/CharacteristicFieldType" },
              is_active: { type: :boolean },
              is_private: { type: :boolean },
              position: { type: :integer },
              options: {
                type: :array,
                items: { "$ref": "#/components/schemas/PropertyCharacteristicOption" },
                description: "Only for field_type=select"
              },
              created_at: { "$ref": "#/components/schemas/Timestamp" },
              updated_at: { "$ref": "#/components/schemas/Timestamp" }
            }
          },

          PropertyCharacteristicOption: {
            type: :object,
            properties: {
              id: { "$ref": "#/components/schemas/UUID" },
              value: { type: :string },
              position: { type: :integer }
            }
          },

          PropertyCharacteristicValue: {
            type: :object,
            properties: {
              id: { "$ref": "#/components/schemas/UUID" },
              title: { type: :string },
              field_type: { type: :string },
              value: {
                oneOf: [
                  { type: :string },
                  { type: :boolean },
                  { type: :number }
                ]
              }
            }
          },

          PropertyCharacteristicCreateRequest: {
            type: :object,
            properties: {
              property_characteristic: {
                type: :object,
                properties: {
                  title: { type: :string },
                  unit: { type: :string },
                  field_type: { "$ref": "#/components/schemas/CharacteristicFieldType" },
                  position: { type: :integer },
                  is_active: { type: :boolean },
                  is_private: { type: :boolean },
                  options_attributes: {
                    type: :array,
                    items: {
                      type: :object,
                      properties: {
                        value: { type: :string },
                        position: { type: :integer }
                      }
                    }
                  }
                },
                required: %w[title field_type]
              }
            },
            required: %w[property_characteristic]
          },

          PropertyCategoryCharacteristicCreateRequest: {
            type: :object,
            properties: {
              property_category_characteristic: {
                type: :object,
                properties: {
                  property_category_id: { "$ref": "#/components/schemas/UUID" },
                  property_characteristic_id: { "$ref": "#/components/schemas/UUID" },
                  position: { type: :integer }
                },
                required: %w[property_category_id property_characteristic_id]
              }
            },
            required: %w[property_category_characteristic]
          },

          # === Property Owner Schemas ===
          PropertyOwner: {
            type: :object,
            properties: {
              id: { "$ref": "#/components/schemas/UUID" },
              first_name: { type: :string },
              last_name: { type: :string },
              middle_name: { type: :string },
              phone: { "$ref": "#/components/schemas/Phone" },
              email: { "$ref": "#/components/schemas/Email" },
              notes: { type: :string },
              role: { "$ref": "#/components/schemas/OwnerRole" },
              is_deleted: { type: :boolean },
              deleted_at: { "$ref": "#/components/schemas/Timestamp" },
              contact_id: { "$ref": "#/components/schemas/UUID" },
              person_id: { "$ref": "#/components/schemas/UUID" },
              property_id: { "$ref": "#/components/schemas/UUID" },
              user: { "$ref": "#/components/schemas/PropertyOwnerUser" },
              properties: {
                type: :array,
                items: { "$ref": "#/components/schemas/PropertyOwnerProperty" }
              },
              created_at: { "$ref": "#/components/schemas/Timestamp" },
              updated_at: { "$ref": "#/components/schemas/Timestamp" }
            }
          },

          PropertyOwnerCreateRequest: {
            type: :object,
            properties: {
              property_owner: {
                type: :object,
                properties: {
                  phone: { "$ref": "#/components/schemas/Phone" },
                  first_name: { type: :string },
                  last_name: { type: :string },
                  middle_name: { type: :string },
                  email: { "$ref": "#/components/schemas/Email" },
                  role: { "$ref": "#/components/schemas/OwnerRole" },
                  notes: { type: :string },
                  user_id: { "$ref": "#/components/schemas/UUID" }
                },
                required: %w[phone]
              }
            },
            required: %w[property_owner]
          },

          PropertyOwnerUser: {
            type: :object,
            properties: {
              id: { "$ref": "#/components/schemas/UUID" },
              phone: { "$ref": "#/components/schemas/Phone" },
              email: { "$ref": "#/components/schemas/Email" },
              role: { "$ref": "#/components/schemas/UserRole" },
              first_name: { type: :string },
              last_name: { type: :string },
              middle_name: { type: :string }
            }
          },

          PropertyOwnerProperty: {
            type: :object,
            properties: {
              id: { "$ref": "#/components/schemas/UUID" },
              title: { type: :string },
              main_photo_url: { type: :string },
              address: {
                type: :object,
                properties: {
                  country: { type: :string },
                  region: { type: :string },
                  city: { type: :string },
                  street: { type: :string },
                  house_number: { type: :string }
                }
              }
            }
          },

          # === Comment Schemas ===
          PropertyComment: {
            type: :object,
            properties: {
              id: { "$ref": "#/components/schemas/UUID" },
              body: { type: :string },
              edited: { type: :boolean },
              edited_at: { "$ref": "#/components/schemas/Timestamp" },
              edit_count: { type: :integer },
              is_deleted: { type: :boolean },
              deleted_at: { "$ref": "#/components/schemas/Timestamp" },
              user: {
                type: :object,
                properties: {
                  id: { "$ref": "#/components/schemas/UUID" },
                  full_name: { type: :string },
                  role: { "$ref": "#/components/schemas/UserRole" }
                }
              },
              created_at: { "$ref": "#/components/schemas/Timestamp" },
              updated_at: { "$ref": "#/components/schemas/Timestamp" }
            }
          },

          PropertyCommentCreateRequest: {
            type: :object,
            properties: {
              property_comment: {
                type: :object,
                properties: {
                  body: { type: :string }
                },
                required: %w[body]
              }
            },
            required: %w[property_comment]
          },

          # === Buy Request Schemas ===
          PropertyBuyRequest: {
            type: :object,
            properties: {
              id: { "$ref": "#/components/schemas/UUID" },
              first_name: { type: :string },
              last_name: { type: :string },
              phone: { "$ref": "#/components/schemas/Phone" },
              comment: { type: :string, maxLength: 1000 },
              status: { "$ref": "#/components/schemas/BuyRequestStatus" },
              response_message: { type: :string, maxLength: 1000 },
              is_deleted: { type: :boolean },
              deleted_at: { "$ref": "#/components/schemas/Timestamp" },
              property_id: { "$ref": "#/components/schemas/UUID" },
              agency_id: { "$ref": "#/components/schemas/UUID" },
              customer_id: { "$ref": "#/components/schemas/UUID" },
              contact_id: { "$ref": "#/components/schemas/UUID" },
              person_id: { "$ref": "#/components/schemas/UUID" },
              user: { "$ref": "#/components/schemas/PropertyOwnerUser" },
              created_at: { "$ref": "#/components/schemas/Timestamp" },
              updated_at: { "$ref": "#/components/schemas/Timestamp" }
            }
          },

          PropertyBuyRequestCreateRequest: {
            type: :object,
            properties: {
              property_buy_request: {
                type: :object,
                properties: {
                  property_id: { "$ref": "#/components/schemas/UUID" },
                  first_name: { type: :string, description: "Required for guests" },
                  last_name: { type: :string },
                  phone: { "$ref": "#/components/schemas/Phone" },
                  comment: { type: :string, maxLength: 1000 }
                },
                required: %w[property_id]
              }
            },
            required: %w[property_buy_request]
          },

          PropertyBuyRequestUpdateRequest: {
            type: :object,
            properties: {
              property_buy_request: {
                type: :object,
                properties: {
                  status: { "$ref": "#/components/schemas/BuyRequestStatus" },
                  response_message: { type: :string, maxLength: 1000 }
                }
              }
            }
          },

          # === Customer Schemas ===
          Customer: {
            type: :object,
            properties: {
              id: { "$ref": "#/components/schemas/UUID" },
              service_type: { "$ref": "#/components/schemas/ServiceType" },
              user_id: { "$ref": "#/components/schemas/UUID" },
              notes: { type: :string },
              is_active: { type: :boolean },
              phone: { "$ref": "#/components/schemas/Phone" },
              phones: {
                type: :array,
                items: { "$ref": "#/components/schemas/Phone" }
              },
              first_name: { type: :string },
              last_name: { type: :string },
              middle_name: { type: :string },
              full_name: { type: :string },
              contact_id: { "$ref": "#/components/schemas/UUID" },
              person_id: { "$ref": "#/components/schemas/UUID" },
              created_at: { "$ref": "#/components/schemas/Timestamp" },
              updated_at: { "$ref": "#/components/schemas/Timestamp" }
            }
          },

          CustomerCreateRequest: {
            type: :object,
            properties: {
              customer: {
                type: :object,
                properties: {
                  phone: { "$ref": "#/components/schemas/Phone" },
                  first_name: { type: :string },
                  last_name: { type: :string },
                  middle_name: { type: :string },
                  email: { "$ref": "#/components/schemas/Email" },
                  extra_phones: {
                    type: :array,
                    items: { "$ref": "#/components/schemas/Phone" },
                    maxItems: 10
                  },
                  service_type: { "$ref": "#/components/schemas/ServiceType" },
                  user_id: { "$ref": "#/components/schemas/UUID" },
                  notes: { type: :string }
                },
                required: %w[phone]
              }
            },
            required: %w[customer]
          },

          # === Contact Schemas ===
          Contact: {
            type: :object,
            properties: {
              id: { "$ref": "#/components/schemas/UUID" },
              agency_id: { "$ref": "#/components/schemas/UUID" },
              person_id: { "$ref": "#/components/schemas/UUID" },
              first_name: { type: :string },
              last_name: { type: :string },
              middle_name: { type: :string },
              email: { "$ref": "#/components/schemas/Email" },
              notes: { type: :string },
              extra_phones: {
                type: :array,
                items: { "$ref": "#/components/schemas/Phone" },
                maxItems: 10
              },
              phone: { "$ref": "#/components/schemas/Phone" },
              phones: {
                type: :array,
                items: { "$ref": "#/components/schemas/Phone" }
              },
              full_name: { type: :string },
              is_deleted: { type: :boolean },
              deleted_at: { "$ref": "#/components/schemas/Timestamp" },
              created_at: { "$ref": "#/components/schemas/Timestamp" },
              updated_at: { "$ref": "#/components/schemas/Timestamp" }
            }
          },

          ContactCreateRequest: {
            type: :object,
            properties: {
              contact: {
                type: :object,
                properties: {
                  phone: { "$ref": "#/components/schemas/Phone" },
                  first_name: { type: :string },
                  last_name: { type: :string },
                  middle_name: { type: :string },
                  email: { "$ref": "#/components/schemas/Email" },
                  extra_phones: {
                    type: :array,
                    items: { "$ref": "#/components/schemas/Phone" },
                    maxItems: 10
                  },
                  notes: { type: :string }
                },
                required: %w[phone first_name]
              }
            },
            required: %w[contact]
          },

          # === Agent Compact ===
          AgentCompact: {
            type: :object,
            properties: {
              id: { "$ref": "#/components/schemas/UUID" },
              first_name: { type: :string },
              last_name: { type: :string },
              middle_name: { type: :string },
              phone: { "$ref": "#/components/schemas/Phone" }
            }
          },

          # === Registration Schemas ===
          RegisterUserRequest: {
            type: :object,
            properties: {
              user: {
                type: :object,
                properties: {
                  phone: { "$ref": "#/components/schemas/Phone" },
                  email: { "$ref": "#/components/schemas/Email" },
                  password: { type: :string, minLength: 12 },
                  password_confirmation: { type: :string },
                  country_code: { "$ref": "#/components/schemas/CountryCode" },
                  first_name: { type: :string },
                  last_name: { type: :string },
                  middle_name: { type: :string },
                  agency_id: { "$ref": "#/components/schemas/UUID" },
                  property_id: { "$ref": "#/components/schemas/UUID" },
                  extra_phones: {
                    type: :array,
                    items: { "$ref": "#/components/schemas/Phone" }
                  }
                },
                required: %w[phone password password_confirmation country_code]
              }
            },
            required: %w[user]
          },

          RegisterAgentWithAgencyRequest: {
            type: :object,
            properties: {
              user: {
                type: :object,
                properties: {
                  phone: { "$ref": "#/components/schemas/Phone" },
                  email: { "$ref": "#/components/schemas/Email" },
                  password: { type: :string, minLength: 12 },
                  password_confirmation: { type: :string },
                  country_code: { "$ref": "#/components/schemas/CountryCode" },
                  first_name: { type: :string },
                  last_name: { type: :string },
                  middle_name: { type: :string }
                },
                required: %w[phone password password_confirmation country_code]
              },
              agency: {
                type: :object,
                properties: {
                  title: { type: :string },
                  slug: { type: :string },
                  custom_domain: { type: :string },
                  agency_plan_id: { "$ref": "#/components/schemas/UUID" }
                },
                required: %w[title]
              }
            },
            required: %w[user agency]
          },

          AuthResponse: {
            type: :object,
            properties: {
              user: { "$ref": "#/components/schemas/User" },
              access_token: { type: :string },
              refresh_token: { type: :string },
              expires_in: { type: :integer }
            },
            required: %w[user access_token refresh_token]
          },

          # === Internal Photo Jobs ===
          PhotoJobRequest: {
            type: :object,
            properties: {
              photo_job: {
                oneOf: [
                  {
                    type: :object,
                    properties: {
                      entity_type: { type: :string, example: "property" },
                      entity_id: { "$ref": "#/components/schemas/UUID" },
                      agency_id: { "$ref": "#/components/schemas/UUID" },
                      user_id: { "$ref": "#/components/schemas/UUID" },
                      file_url: { type: :string },
                      is_main: { type: :boolean },
                      position: { type: :integer },
                      access: { type: :string, enum: %w[public private] }
                    },
                    required: %w[entity_type entity_id agency_id user_id file_url]
                  },
                  {
                    type: :array,
                    items: {
                      type: :object,
                      properties: {
                        entity_type: { type: :string },
                        entity_id: { "$ref": "#/components/schemas/UUID" },
                        agency_id: { "$ref": "#/components/schemas/UUID" },
                        user_id: { "$ref": "#/components/schemas/UUID" },
                        file_url: { type: :string },
                        is_main: { type: :boolean },
                        position: { type: :integer },
                        access: { type: :string }
                      }
                    }
                  }
                ]
              }
            }
          },

          PhotoJobDeleteRequest: {
            type: :object,
            properties: {
              entity_type: { type: :string, example: "property" },
              entity_id: { "$ref": "#/components/schemas/UUID" },
              file_urls: {
                type: :array,
                items: { type: :string }
              }
            },
            required: %w[entity_type entity_id file_urls]
          }
        }
      },
      security: [ { Bearer: [] } ],
      paths: {}
    }
  }

  config.openapi_format = :yaml
end
