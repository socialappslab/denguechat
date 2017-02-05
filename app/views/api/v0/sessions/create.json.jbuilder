
json.user do
  json.token @user.jwt_token
  json.(@user, :id, :display_name)
  json.profile_photo @user.profile_photo.url(:thumbnail)
  json.neighborhood do
    json.(@user.neighborhood, :id, :geographical_display_name)
    json.questions HouseQuiz.questions
  end

  json.breeding_sites BreedingSite.order("description_in_es ASC") do |bs|
    json.(bs, :id, :description)
    json.elimination_methods bs.elimination_methods.order("description_in_es ASC") do |em|
      json.(em, :id, :description)
    end
  end

  json.neighborhoods Neighborhood.order("name ASC") do |n|
    json.(n, :id, :name)
  end

  json.total_points @user.total_total_points
  json.green_locations GreenLocationRankings.score_for_user(@user).to_i
end