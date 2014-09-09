#!/bin/env ruby
# encoding: utf-8

class UsersController < ApplicationController
  before_filter :require_login,             :only => [:edit, :update, :index, :show]
  before_filter :ensure_team_chosen,        :only => [:show]
  before_filter :identify_user,             :only => [:edit, :update, :show]
  before_filter :ensure_proper_permissions, :only => [:index, :phones]

  #----------------------------------------------------------------------------
  # GET /users/

  def index
    if params[:q].nil? or params[:q] == ""
      @users = User.residents.order(:first_name)
      @sponsors = User.where(:role => "lojista").order(:first_name)
      @verifiers = User.where(:role => "verificador").order(:first_name)
      @visitors = User.where(:role => "visitante").order(:first_name)
    else
      @users = User.where(:role => "morador").where('lower(first_name) LIKE lower(?)', params[:q] + "%").order(:first_name)
      @sponsors = User.where(:role => "lojista").where('lower(first_name) LIKE lower(?)', params[:q] + "%").order(:first_name)
      @sponsors = House.where('lower(name) LIKE lower(?)', params[:q] + "%").map { |house| house.user }.compact
      @verifiers = User.where(:role => "verificador").where('lower(first_name) LIKE lower(?)', params[:q] + "%").order(:first_name)
      @visitors = User.where(:role => "visitante").where('lower(first_name) LIKE lower(?)', params[:q] + "%").order(:first_name)
    end
    @prizes = Prize.where(:is_badge => false)
    authorize! :assign_roles, User

    respond_to do |format|
      format.html
      format.json { render json: { users: @users}}
    end
  end

  #----------------------------------------------------------------------------
  # GET /users/phones

  def phones
    @users = User.all
  end

  #----------------------------------------------------------------------------
  # GET /users/1/

  def show
    head :not_found and return if @user.nil?
    head :not_found and return if ( @user != @current_user && @user.role == User::Types::SPONSOR )

    @post         = Post.new
    @neighborhood = @user.neighborhood || Neighborhood.first
    @house        = @user.house
    @badges       = @user.badges
    @user_posts   = @user.posts
    @reports      = @user.reports
    @notices      = @neighborhood.notices.order("updated_at DESC")
    @teams        = @user.teams

    # Avoid displaying coupons that expired and were never redeemed.
    @coupons = @user.prize_codes.reject {|coupon| coupon.expired? }

    # Find if user can redeem prizes.
    @prizes            = Prize.where('stock > 0').where('expire_on >= ? OR expire_on is NULL', Time.new).where(:is_badge => false)
    @redeemable_prizes = @prizes.where("cost <= ?", @user.total_points).shuffle

    # Load the community news feed. We explicitly limit activity to this month
    # so that we don't inadvertedly create a humongous array.
    # TODO: As activity on the site picks up, come back to rethink this inefficient
    # query.
    # TODO: Move the magic number '4.weeks.ago'
    if @current_user == @user
      neighborhood_reports = @neighborhood.reports.where("created_at > ?", 4.weeks.ago)
      neighborhood_reports = neighborhood_reports.find_all {|r| r.is_public? }

      # Now, let's load all the users, and their posts.
      neighborhood_posts = []
      @neighborhood.members.each do |m|
        user_posts = m.posts.where("created_at > ?", 4.weeks.ago)
        neighborhood_posts << user_posts
      end
      neighborhood_posts.flatten!

      @news_feed = (neighborhood_reports + neighborhood_posts + @notices.to_a).sort{|a,b| b.created_at <=> a.created_at }
    else
      @news_feed = (@reports.to_a + @user_posts.to_a + @notices.to_a).sort{|a,b| b.created_at <=> a.created_at }
    end

    respond_to do |format|
      format.html
      format.json { render json: {user: @user, house: @house, badges: @badges}}
    end
  end

  #----------------------------------------------------------------------------
  # GET /users/new

  def new
    @user = User.new
  end

  #----------------------------------------------------------------------------

  # TODO: Move this into CoordinatorController. For now, we'll use this legacy
  # hack.
  def special_new
    authorize! :edit, User.new
    @user ||= User.new
    render "coordinators/users/edit" and return
  end

  #----------------------------------------------------------------------------

  def create
    params[:user].each{|key,val| params[:user][key] = params[:user][key].strip}

    @user = User.new(params[:user])
    if @user.save

      # Set the default language based on selected neighborhood.
      tepalcingo = Neighborhood.find_by_name("Tepalcingo")
      if tepalcingo && @user.neighborhood_id == tepalcingo.id
        cookies[:locale_preference] = "es"
      else
        cookies[:locale_preference] = I18n.default_locale
      end

      cookies[:auth_token] = @user.auth_token
      flash[:notice] = I18n.t("views.users.create_success_flash") + " " + I18n.t("views.teams.call_to_action_flash")
      redirect_to teams_path and return
    else
      render new_user_path(@user)
    end
  end

  #----------------------------------------------------------------------------
  # GET /users/1/edit

  def edit
    authorize!(:edit, @user) if @user != @current_user

    @verifiers = User.where(:role => User::Types::VERIFIER).map { |v| {:value => v.id, :label => v.full_name}}
    @residents = User.residents.map { |r| {:value => r.id, :label => r.full_name}}
  end

  #----------------------------------------------------------------------------
  # PUT /users/1

  def update
    # NOTE: These horrendous actions are a result of trying to save form information,
    # even when later information may not be correct.
    @user.update_attribute(:gender, params[:user][:gender])
    @user.update_attribute(:neighborhood_id, params[:user][:neighborhood_id])
    @user.update_attribute(:first_name, params[:user][:first_name])
    @user.update_attribute(:last_name, params[:user][:last_name])
    @user.update_attribute(:nickname, params[:user][:nickname])

    @user.update_attributes(params[:user].slice(:phone_number, :carrier, :prepaid)) if params[:cellphone] == "false"

    # TODO: Clean up and clarify the intent of this line.
    user_params = params[:user].slice(:profile_photo, :gender, :username, :email, :first_name, :last_name, :nickname, :neighborhood_id, :phone_number, :cellphone, :carrier, :prepaid)

    if @user.update_attributes(user_params)
      # Identify the recruiter for this user.
      recruiter = User.find_by_id( params[:recruiter_id] )
      if recruiter
        @user.recruiter = recruiter

        # Only add points to the recruiter if the user isn't fully registered.
        recruiter.total_points += 50 if @user.is_fully_registered == false


        recruiter.save
      end

      @user.update_attribute(:is_fully_registered, true)
    else
      render "edit" and return
    end

    redirect_to edit_user_path(@user), :flash => { :notice => 'Perfil atualizado com sucesso!' }
  end


  #----------------------------------------------------------------------------

  def destroy
    @user = User.find(params[:id])

    # Destroy the user's house if he is the only one in the house.
    if @user.house && @user.house.members.count == 1
      @user.house.destroy
    end

    # Finally, let's delete the user.
    @user.destroy

    redirect_to users_url, :notice => "Usuário deletado com sucesso." and return
  end

  #----------------------------------------------------------------------------
  # GET /users/1/buy_prize/1

  def buy_prize
    @user       = User.find(params[:id])
    @prize      = Prize.find(params[:prize_id])
    @prize_code = @user.generate_coupon_for_prize(@prize)
    render :partial => "prizes/prizeconfirmation", :locals => {:bought => @prize_code.present?}
  end

  #----------------------------------------------------------------------------

  def special_create
    authorize! :edit, User

    @user = User.new(params[:user])
    if @user.save
      redirect_to coordinator_create_users_path, :flash => { :notice => I18n.t("views.coordinators.users.success_create_flash")}
    else
      render "coordinators/users/edit", flash: { alert: @user.errors.full_messages.join(', ')}
    end
  end

  #----------------------------------------------------------------------------

  def block
    @user = User.find(params[:id])
    @user.is_blocked = !@user.is_blocked
    if @user.save
      if @user.is_blocked
        redirect_to users_path, notice: "Usuário bloqueado com sucesso."
      else
        redirect_to users_path, notice: "Usuário desbloqueado com sucesso."
      end
    else
      redirect_to users_path, notice: "There was an error blocking the user"
    end
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def identify_user
    @user = User.find(params[:id])
  end

  #----------------------------------------------------------------------------

end
