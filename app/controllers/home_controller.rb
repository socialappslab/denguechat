class HomeController < ApplicationController
  #----------------------------------------------------------------------------
  # GET /

  def index
    @user = User.new
    
    @all_neighborhoods     = Neighborhood.order(:id).limit(3)
    @selected_neighborhood = @all_neighborhoods.first

    # Display ordered news.
    @notices  = @selected_neighborhood.notices.order("date DESC").limit(6)

    # Display 5 non-empty houses.
    @houses = @selected_neighborhood.houses.where("house_type != ?", User::Types::SPONSOR)
    @houses = @houses.find_all {|h| h.members.count > 0}
    @houses = @houses.shuffle[0..4]

    # Display active prizes.
    @prizes  = Prize.where('stock > 0 AND (expire_on IS NULL OR expire_on > ?)', Time.new).order("RANDOM()").limit(3)
  end

  #----------------------------------------------------------------------------
  # GET /howto

  def howto
    @sections = DocumentationSection.order("order_id ASC")
  end

  #----------------------------------------------------------------------------
  # POST /neighborhood-search
  #
  # Parameters:
  # { "neighborhood"=>{"name"=>"Vila Autódromo"} }

  def neighborhood_search
    neighborhood = Neighborhood.find_by_name(params[:neighborhood][:name])
    redirect_to neighborhood_path(neighborhood)
  end

  #----------------------------------------------------------------------------
end
