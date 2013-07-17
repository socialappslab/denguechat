#!/bin/env ruby
# encoding: utf-8

class ReportsController < ApplicationController

  before_filter :require_login, :except => [:sms, :verification]

  def index 
    @current_report = params[:report]    
    @current_user != nil ? @highlightReportItem = "nav_highlight" : @highlightReportItem = ""
    params[:view] = 'recent' if params[:view].nil? || params[:view] == "undefined"
    params[:view] == 'recent' ? @reports_feed_button_active = "active" : @reports_feed_button_active = ""
    params[:view] == 'open' ? @reports_open_button_active = "active" : @reports_open_button_active = ""
    params[:view] == 'eliminate' ? @reports_resolved_button_active = "active" : @reports_resolved_button_active = ""
    params[:view] == 'make_report' ?  @make_report_button_active = "active" : @make_report_button_active = ""
    
    if params[:view] == "make_report"
      @report = Report.new
    end
    
    @elimination_method_select = EliminationMethods.field_select
       
    reports_with_status_filtered = []
    locations = []
    
    Report.order("created_at DESC").each do |report|
      if params[:view] == 'recent' || params[:view] == 'make_report'
        reports_with_status_filtered << report
        locations << report.location
      elsif params[:view] == 'open' && report.status == :reported
        reports_with_status_filtered << report
        locations << report.location
      elsif params[:view] == 'eliminate' && report.status == :eliminated
        reports_with_status_filtered << report
        locations << report.location
      end
    end
    
    # @map_json = locations.to_gmaps4rails
    @map_json = nil
    @reports = reports_with_status_filtered
    @open_feed = @reports
    @eliminate_feed = @reports
  end
  
  def new
    @report = Report.new
  end

  def create    

    if request.post?
      location = Location.find_or_create(params[:location])
      @report = Report.create_from_user(params[:report][:report], :status => :reported, :reporter => @current_user, :location => location)
      @report.before_photo = params[:report][:before_photo]
    
      if @report.save
        if @current_user != nil
          @current_user.update_attribute(:points, @current_user.points + 100)
        end
        
        flash[:notice] = 'Report posted succesfully.'
        redirect_to :action=>'index', view: 'recent'
      else
        render "new"
      end
    end
  end
  
  def edit
    @report = @current_user.created_reports.find(params[:id])
  end
    
  def verification
    @unverified_reports = Report.unverified_reports
  end
  
  def sms
    logger = Logger.new(STDOUT)  
    logger.info params[:Body].inspect
    logger.info params[:From].inspect
    
    @account_sid = 'AC696e86d23ebba91cbf65f1383cf63e7d'
    @auth_token = 'a49ee186176ead11c760fd77aeaeb26c'
    @client = Twilio::REST::Client.new(@account_sid, @auth_token)
    @account = @client.account
    
    login = params[:From].delete('+')
    user = User.find_by_username(login)    
  
    if !user
      password = ApplicationHelper.temp_password_generator
      logger.info password
      user = User.new(:username => login, :password => password, :password_confirmation => password)
      logger.info user.inspect
      
      if user.save
        logger.info "new user created and send welcome report"
        response = 'username: ' + params[:From].delete('+') + ' Temporary password: ' + password + ' To login to the site, go to http://reportdengue.herokuapp.com/login' 
        @account.sms.messages.create(:from => '+15109854798', :to => params[:From], :body  => response)
      end
    end
    
    logger.info "parsing the sms text..."
    parser = MailParser::Parser.new(params[:Body], 'sms')
    
    if parser.report && parser.nation && parser.city && parser.address && parser.state
      
      if parser.neighborhood.nil?
        neighborhood = ""
      else
        neighborhood = parser.neighborhood
      end
      
      logger.debug "Parsed data = nation: " + parser.nation + " address: " + parser.address + " neighborhood: " + neighborhood + " city: " + parser.city + " state: " + parser.state + " report: " + parser.report
      report = Report.new(:user_id => user.id, :nation => parser.nation, :address => parser.address, :neighborhood => neighborhood, :city => parser.city, :state => parser.state, :report => parser.report)
      
      if report.save 
        logger.info("New report sucessfully added")
        @account.sms.messages.create(:from => '+15109854798', :to => params[:From], :body  => 'Congratulation! your report has been processed and added to our database')
      else
        logger.info("New report failed to add")
        @account.sms.messages.create(:from => '+15109854798', :to => params[:From], :body  => 'I am sorry, but something went wrong in our system. We were unable to add your report')
      end
    else
      logger.info "No match was found or some fields were not specified"
      @account.sms.messages.create(:from => '+15109854798', :to => params[:From], :body  => 'We could not understand your report because some hashtags were missing...')
    end
  end

  def update
    if request.put?
    
      if !params[:eliminate]
        flash[:notice] = 'You must upload a photo'
        redirect_to(:back)
        return
      end
      
      @report = Report.find(params[:report_id])
                         
      if params[:eliminate][:after_photo] != nil
        # user uploaded an after photo
        begin
          @report.after_photo = params[:eliminate][:after_photo]
          @report.update_attribute(:status_cd, 1)
          @report.update_attribute(:eliminator_id, @current_user.id)
          @report.touch(:eliminated_at)
        rescue
          flash[:notice] = 'An error has occurred!'
          redirect_to(:back)
          return
        end
        
        @report.elimination_type = EliminationMethods.getEliminationTypeFromMethodSelect(params["method_of_elimination"])
        @report.elimination_method = params["method_of_elimination"]
        
        if @report.save
          if @current_user != nil
            @current_user.update_attribute(:points, @current_user.points + 400)
          end
          flash[:notice] = 'You eliminated this report!'
          redirect_to(:back)
        else
          #for some reason save causes error here, but in view it looks OK
          flash[:notice] = 'An error has occurred'
          redirect_to(:back)
        end
      
      elsif params[:eliminate][:before_photo] != nil
        # user uploaded a before photo
        @report.before_photo = params[:eliminate][:before_photo]
        if @report.save
          flash[:notice] = "You updated before photo"
          redirect_to(:back)
        else
          flash[:notice] = "An error has occured"
          redirect_to(:back)
        end
      else
        redirect_to(:back)
      end 
    end
  end
  
  def destroy
    @current_user.created_reports.find(params[:id]).destroy
    redirect_to(:back)
  end
end
