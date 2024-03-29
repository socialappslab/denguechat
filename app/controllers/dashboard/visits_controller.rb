# -*- encoding : utf-8 -*-

class Dashboard::VisitsController < Dashboard::BaseController
  before_filter :identify_neighborhood, :only => [:index]

  #----------------------------------------------------------------------------
  # GET /dashboard/visits

  def index
    authorize :dashboard, :index?
    @city = @current_user.city

    # @breadcrumbs << {:name => I18n.t("views.dashboard.navigation.visits"), :path => request.path}
  end

  #----------------------------------------------------------------------------

end
