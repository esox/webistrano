class AddRecipeConfigurationToParams < ActiveRecord::Migration
  def self.up
    add_column :configuration_parameters, :recipe_id, :integer
    add_column :configuration_parameters, :recipe_scope, :text
    add_column :configuration_parameters, :description, :text
    add_column :configuration_parameters, :validations, :text
  end

  def self.down
    remove_column :configuration_parameters, :recipe_id
    remove_column :configuration_parameters, :recipe_scope
    remove_column :configuration_parameters, :description
    remove_column :configuration_parameters, :validations
  end
end
