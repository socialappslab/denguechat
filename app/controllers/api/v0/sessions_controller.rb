class API::V0::SessionsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token, :only => [:create]

  #----------------------------------------------------------------------------
  # POST /api/v0/sessions
  def create
    device   = params[:device]

    user = User.find_by_username( params[:username] )
    user = User.find_by_email( params[:username] ) if user.nil?

    puts "user.inspect: #{user.inspect} | user.authenticate(params[:password]): #{user.authenticate(params[:password])}"

    if user.present? && user.authenticate(params[:password]) && device
      ds         = DeviceSession.new
      ds.user_id = user.id
      ds.token   = SecureRandom.uuid
      ds.save!

      render :json => { :device_session => { :token => ds.token } }, :status => 200
    else
      raise API::V0::Error.new("Invalid email or password. Please try again.", 401) and return
    end

  end

  #----------------------------------------------------------------------------
end