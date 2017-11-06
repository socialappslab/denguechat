# -*- encoding : utf-8 -*-
class API::V0::SessionsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token
  before_filter :authenticate_user_via_jwt, :only => [:current]
  before_filter :current_user_via_jwt,      :only => [:current]

  #----------------------------------------------------------------------------
  # POST /api/v0/sessions
  def create
    user = User.find_by_username( params[:username] )
    user = User.find_by_email( params[:username] ) if user.nil?

    if user.present? && user.authenticate(params[:password])
      @user = user
      render "api/v0/sessions/create" and return
    else
      raise API::V0::Error.new("Invalid email or password. Please try again.", 401) and return
    end
  end

  #----------------------------------------------------------------------------
  # GET /api/v0/sessions/current

  def current
    @user = @current_user
    render "api/v0/sessions/create" and return
  end

  #----------------------------------------------------------------------------

  #----------------------------------------------------------------------------
  # GET /api/v0/sessions/registrations

  def registrations
    @organization = Organization.find_by_id(params[:user].neighborhood_id)

    # At this point, the user does NOT exist. Let's create them here.
    @user          = User.new(params[:user])
    if @user.save
      Membership.create(:user_id => @user.id, :organization_id => @organization.id, :role => Membership::Roles::RESIDENT, :active => true)
      render :json => {}, :status => :ok and return
    else
      raise API::V0::Error.new(@user.errors.full_messages[0], 422) and return
    end
  end

  #----------------------------------------------------------------------------
end
