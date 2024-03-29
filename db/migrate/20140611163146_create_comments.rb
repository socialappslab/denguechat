# -*- encoding : utf-8 -*-
class CreateComments < ActiveRecord::Migration
  def up
    create_table :comments do |t|
      t.integer :user_id
      t.integer :commentable_id
      t.string  :commentable_type
      t.text    :content
      t.timestamps
    end
  end

  def down
    drop_table :comments
  end
end
