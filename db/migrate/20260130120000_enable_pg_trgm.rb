# frozen_string_literal: true

class EnablePgTrgm < ActiveRecord::Migration[8.0]
  def change
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")
  end
end
