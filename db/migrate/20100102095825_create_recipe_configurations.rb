class CreateRecipeConfigurations < ActiveRecord::Migration
  def self.up
    create_table :recipe_configurations do |t|
    end
  end

  def self.down
    drop_table :recipe_configurations
  end
end
