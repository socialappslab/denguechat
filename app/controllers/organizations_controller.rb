# -*- encoding : utf-8 -*-
#!/bin/env ruby
# encoding: utf-8

class OrganizationsController < ApplicationController
  before_filter :require_login
  before_filter :identify_org
  before_filter :identify_selected_membership
  before_filter :update_breadcrumbs
  after_filter :verify_authorized
  before_action :calculate_header_variables


  #----------------------------------------------------------------------------
  # GET /settings

  def settings
    @organization = current_user.selected_membership.organization
    authorize @organization
  end

  #----------------------------------------------------------------------------
  # GET /settings/users

  def users
    authorize @organization

    @memberships = @organization.memberships.includes(:user).order("user_id")
    @breadcrumbs = nil
  end

  #----------------------------------------------------------------------------
  # GET /settings/teams

  def teams

    @teams = @organization.teams.order("id ASC")
    authorize @organization
  end

  #----------------------------------------------------------------------------
  # GET /settings/assignments

  def assignments
    authorize @organization
    @city = current_user.city
    @future_assignments = Assignment.where('date > ?', DateTime.now).order(date: 'desc').limit(3)
  end

  #----------------------------------------------------------------------------
  # PUT /organizations/:id

  def update
    @org = @selected_membership.organization
    authorize(@org)
    @org.name = params[:organization][:name]
    if @org.save
      redirect_to settings_path and return
    else
      render settings_path and return
    end
  end

  #----------------------------------------------------------------------------

  private

  #----------------------------------------------------------------------------

  def identify_org
    @organization = current_user.selected_membership.organization
  end

  def update_breadcrumbs
    @breadcrumbs = nil
  end
end
