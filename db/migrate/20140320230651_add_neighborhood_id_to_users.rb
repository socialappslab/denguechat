# -*- encoding : utf-8 -*-
class AddNeighborhoodIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :neighborhood_id, :integer
  end
end
