# -*- encoding : utf-8 -*-
class CitiesController < ApplicationController
  include GreenLocationRankings
  before_action :calculate_header_variables

  #----------------------------------------------------------------------------
  # GET /cities

  def index
    @neighborhoods = Neighborhood.all
  end

  #----------------------------------------------------------------------------
  # GET /cities/:id

  def show
    @city          = City.find( params[:id] )
    @cities        = City.order("name ASC")
    @neighborhoods = Neighborhood.where(:city_id => @city.id)

    if @current_user.present?
      Analytics.track( :user_id => @current_user.id, :event => "Visited city page", :properties => {:city => @city.name}) if Rails.env.production?
    else
      Analytics.track( :anonymous_id => SecureRandom.base64, :event => "Visited city page", :properties => {:city => @city.name}) if Rails.env.production?
    end

    # Let's try to retrieve
    #@green_location_rankings = GreenLocationRankings.top_ten_for_city(@city)
    @rankings_points = User.find_by_sql("select * from users where neighborhood_id IN(
      select n.id from 
        neighborhoods as n
        join
        Cities as c
      ON n.city_id = c.id
      where n.city_id ="+@city.id.to_s+"
    )
    ORDER BY total_points DESC 
    LIMIT (5)")
    @neighborhood_rankings = @neighborhoods.map do |n|
      {:id => n.id, :score => GreenLocationSeries.get_latest_count_for_neighborhood(n).to_i}
    end

    @breadcrumbs << {:name => @city.name, :path => city_path(@city)}
  end


  #----------------------------------------------------------------------------

  private
end
