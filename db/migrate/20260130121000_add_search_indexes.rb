# frozen_string_literal: true

class AddSearchIndexes < ActiveRecord::Migration[8.0]
  def change
    add_index :properties, :title,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: "index_properties_on_title_trgm"

    add_index :contacts, :email,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: "index_contacts_on_email_trgm"

    add_index :people, :normalized_phone,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: "index_people_on_normalized_phone_trgm"

    add_index :users, :email,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: "index_users_on_email_trgm"

    add_index :property_categories, :title,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: "index_property_categories_on_title_trgm"

    add_index :property_characteristics, :title,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: "index_property_characteristics_on_title_trgm"

    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE INDEX index_property_locations_on_search_address_trgm
          ON property_locations
          USING gin ((
            coalesce(country, '') || ' ' ||
            coalesce(region, '') || ' ' ||
            coalesce(city, '') || ' ' ||
            coalesce(street, '') || ' ' ||
            coalesce(house_number, '')
          ) gin_trgm_ops);
        SQL

        execute <<~SQL
          CREATE INDEX index_contacts_on_full_name_trgm
          ON contacts
          USING gin ((
            coalesce(last_name, '') || ' ' ||
            coalesce(first_name, '') || ' ' ||
            coalesce(middle_name, '')
          ) gin_trgm_ops);
        SQL

        execute <<~SQL
          CREATE INDEX index_property_categories_on_id_trgm
          ON property_categories
          USING gin ((id::text) gin_trgm_ops);
        SQL

        execute <<~SQL
          CREATE INDEX index_property_characteristics_on_id_trgm
          ON property_characteristics
          USING gin ((id::text) gin_trgm_ops);
        SQL
      end

      dir.down do
        execute "DROP INDEX IF EXISTS index_property_locations_on_search_address_trgm"
        execute "DROP INDEX IF EXISTS index_contacts_on_full_name_trgm"
        execute "DROP INDEX IF EXISTS index_property_categories_on_id_trgm"
        execute "DROP INDEX IF EXISTS index_property_characteristics_on_id_trgm"
      end
    end
  end
end
