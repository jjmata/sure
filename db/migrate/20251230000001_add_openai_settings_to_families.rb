class AddOpenaiSettingsToFamilies < ActiveRecord::Migration[7.2]
  def change
    add_column :families, :openai_access_token, :string
    add_column :families, :openai_uri_base, :string
    add_column :families, :openai_model, :string
    add_column :families, :openai_json_mode, :string
  end
end
