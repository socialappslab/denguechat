# encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :current_user
  before_filter :set_locale

  #----------------------------------------------------------------------------

  rescue_from CanCan::AccessDenied do |exception|
    Rails.logger.debug "Access denied on #{exception.action} #{exception.subject.inspect}"
    render :file => "public/401.html", :status => :unauthorized
  end

  #----------------------------------------------------------------------------
  # This is used for all ActiveAdmin-related resources.

  def set_active_admin_locale
    I18n.locale = :en
  end

  #----------------------------------------------------------------------------

  protected

  #----------------------------------------------------------------------------

  def require_login
    @current_user ||= User.find_by_auth_token( params[:auth_token] )
    if @current_user.nil?
      flash[:alert] = I18n.t("views.application.login_required")
      redirect_to new_user_path
    end
  end

  #----------------------------------------------------------------------------
  # Ensure that only coordinators are allowed access.

  def ensure_proper_permissions
    puts "@current_user && @current_user.coordinator?: #{@current_user && @current_user.coordinator?}"
    return if @current_user && @current_user.coordinator?

    flash[:alert] = I18n.t("views.application.permission_required")
    redirect_to root_path and return
  end

  #----------------------------------------------------------------------------

  def current_user
    @current_user ||= User.find_by_auth_token(cookies[:auth_token]) if cookies[:auth_token]
  end

  #----------------------------------------------------------------------------

  private

  def ensure_team_chosen
    return if @current_user.nil?

    if @current_user.teams.count == 0
      flash[:notice] = I18n.t("views.teams.call_to_action_flash")
      redirect_to teams_path and return
    end
  end

  def set_locale
    locale = (params[:locale] || I18n.default_locale).to_s
    return unless ["es", "pt"].include?(locale)

    # Set the locale, and update the user's locale, if applicable.
    I18n.locale = locale
    if @current_user && @current_user.locale != locale
      @current_user.update_column(:locale, locale)
    end

    if I18n.locale == "es"
      @facebook_locale = "es_LA"
    else
      @facebook_locale = "pt_BR"
    end
  end

  #----------------------------------------------------------------------------


end
