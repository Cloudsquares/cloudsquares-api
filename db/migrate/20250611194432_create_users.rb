class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid do |t|
      t.string :phone, null: false
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :first_name, null: false
      t.string :last_name
      t.string :middle_name
      t.integer :role, null: false, default: 5
      t.string :country_code, null: false, default: "RU"
      t.string :user_status, null: false, default: "active"
      t.text :user_status_description
      t.datetime :status_changed_at
      t.uuid :status_changed_by_id
      t.datetime :last_sign_in_at

      t.timestamps
    end

    add_index :users, :phone, unique: true
    add_index :users, :email, unique: true
    add_index :users, :user_status
    add_index :users, :status_changed_by_id

    add_foreign_key :users, :users, column: :status_changed_by_id
  end
end
