# encoding: utf-8
class TeamsController < ApplicationController
  before_filter :require_login
  before_filter :identify_neighborhood,            :except => [:administer]
  before_filter :ensure_proper_permissions, :only => [:administer, :block]
  before_filter :load_associations,         :only => [:show, :feed]

  #----------------------------------------------------------------------------
  # GET /teams

  def index
    @teams = Team.where(:neighborhood_id => @neighborhood.id).where(:blocked => [nil, false])
    @team  = Team.new

    # Calculate ranking for each team.
    if params[:sort].present? && params[:sort].downcase == "name"
      @team_rankings = @teams.order("name").map {|t| [t, t.total_points]}
    else
      team_rankings  = @teams.map {|t| [t, t.total_points]}
      @team_rankings = team_rankings.sort {|a, b| a[1] <=> b[1]}.reverse
    end
  end

  #----------------------------------------------------------------------------
  # GET /teams/1

  def show
    @post    = Post.new

    @total_reports = @reports.count
    @total_points  = @users.sum(:total_points)
    @reports       = @reports[0..5]
    @posts         = @users.map {|u| u.posts.limit(3)}.flatten
    @activity_feed = (@reports.to_a + @posts.to_a).sort{|a,b| b.created_at <=> a.created_at }
  end

  #----------------------------------------------------------------------------
  # GET /teams/1/feed

  def feed
    @post    = Post.new
    @posts   = @users.map {|u| u.posts}.flatten
    @activity_feed = (@reports.to_a + @posts.to_a).sort{|a,b| b.created_at <=> a.created_at }
  end

  #----------------------------------------------------------------------------
  # POST /teams

  def create
    @team                 = Team.new(params[:team])
    @team.neighborhood_id = @neighborhood.id

    if @team.save
      # If the team was successfully created, create the team membership
      # since any user who creates a team must be interested in joining it,
      # automatically.
      TeamMembership.create(:team_id => @team.id, :user_id => @current_user.id, :verified => true)
      flash[:notice] = I18n.t("views.teams.success_create_flash")

      respond_to do |format|
        format.html { redirect_to teams_path and return }
        format.json { render :json => {:team => @team, :success => flash[:notice]}, :status => :ok }
      end
    else
      @teams = Team.where(:neighborhood_id => @neighborhood.id).where(:blocked => [nil, false])

      # Calculate ranking for each team.
      team_rankings  = @teams.map {|t| [t, t.total_points]}
      @team_rankings = team_rankings.sort {|a, b| a[1] <=> b[1]}.reverse

      # Let's simplify the user's life by displaying the form in case of failure.
      # After all, if we've reached this point, then the user's last interaction
      # was with the new team form.
      respond_to do |format|
        format.html {
          flash[:show_new_team_form] = true
          render "index" and return
        }
        format.json { render :json => {:errors => @team.errors.full_messages} , :status => :ok }
      end
    end
  end

  #----------------------------------------------------------------------------
  # GET /teams/administer

  def administer
    @neighborhood = Neighborhood.find_by_id( params[:neighborhood_id] )

    if @neighborhood.present?
      @teams = Team.where(:neighborhood_id => @neighborhood.id)
    else
      @teams = Team.all
    end
  end

  #----------------------------------------------------------------------------
  # POST /teams/1/join

  def join
    @team         = Team.find( params[:id] )
    membership = TeamMembership.find_or_create_by_user_id_and_team_id(@current_user.id, @team.id)
    if membership.save
      flash[:notice] = I18n.t("views.teams.success_join_flash")
      redirect_to :back and return
    else
      @teams = Team.all

      flash[:alert] = I18n.t("views.application.error")
      render "teams/index" and return
    end
  end

  #----------------------------------------------------------------------------
  # POST /teams/1/leave

  def leave
    membership = @current_user.team_memberships.find { |tm| tm.team_id.to_s == params[:id].to_s }

    respond_to do |format|
      if membership && membership.destroy
        flash[:notice] = I18n.t("views.teams.success_leave_flash")

        format.html { redirect_to :back and return }
        format.json { render :json => :ok and return }
      else
        flash[:alert] = I18n.t("views.application.error")

        format.html { redirect_to :back and return }
        format.json { render :json => :bad_request and return }
      end
    end
  end

  #----------------------------------------------------------------------------
  # PUT /teams/1/block

  def block
    @team         = Team.find(params[:id])
    @team.blocked = !@team.blocked

    respond_to do |format|
      if @team.save
        notice = (@team.blocked ? I18n.t("views.teams.team_successfully_blocked") : I18n.t("views.teams.team_successfully_unblocked"))

        flash[:notice] = notice
        format.html { redirect_to :back and return }
      else
        flash[:alert] = I18n.t("views.application.error")
        format.html { redirect_to :back and return }
      end
    end
  end

  #----------------------------------------------------------------------------

  private

  def identify_neighborhood
    @neighborhood = @current_user.neighborhood
  end

  #----------------------------------------------------------------------------

  def load_associations
    @team         = Team.find_by_id( params[:team_id] )
    @team         = Team.find(params[:id]) if @team.blank?

    @users   = @team.users.includes(:posts)
    @reports = @users.map {|u| u.reports}.flatten
  end

  #----------------------------------------------------------------------------

end
