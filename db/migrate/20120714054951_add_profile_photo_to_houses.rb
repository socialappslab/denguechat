# -*- encoding : utf-8 -*-
class AddProfilePhotoToHouses < ActiveRecord::Migration
  def change
    add_attachment :houses, :profile_photo
  end
end
