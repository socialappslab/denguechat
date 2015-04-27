# -*- encoding : utf-8 -*-
class CreateLikes < ActiveRecord::Migration
  def up
    create_table :likes do |t|
      t.integer :user_id
      t.integer :likeable_id
      t.string  :likeable_type
      
      t.timestamps
    end
  end

  def down
    drop_table :likes
  end
end
