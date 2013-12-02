#!/bin/env ruby
# encoding: utf-8

class ReportsController < ApplicationController

  before_filter :require_login, :except => [:sms, :verification, :gateway, :notifications, :creditar, :credit, :discredit]
  before_filter :find_by_id, only: [:creditar, :credit, :discredit]

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
    @elimination_types = EliminationMethods.types
    reports_with_status_filtered = []
    locations = []
    open_locations = []
    eliminated_locations = []
    @prantinho = EliminationMethods.prantinho
    @pneu = EliminationMethods.pneu
    @lixo = EliminationMethods.lixo
    @pequenos = EliminationMethods.pequenos
    @grandes = EliminationMethods.grandes
    @calha = EliminationMethods.calha
    @registros = EliminationMethods.registros
    @laje = EliminationMethods.laje
    @piscinas = EliminationMethods.piscinas
    @pocas = EliminationMethods.pocas
    @ralos = EliminationMethods.ralos
    @plantas = EliminationMethods.plantas
    @points = EliminationMethods.points

    # @reports = Report.sort_by(:)
    @reports = Report.all.reject(&:completed_at) + Report.select(&:completed_at).sort_by(&:completed_at).reverse
    @reports.each do |report|
      if (report.reporter == @current_user or report.elimination_type)
        if params[:view] == 'recent' || params[:view] == 'make_report'
          reports_with_status_filtered << report
          if report.status_cd == 1
            eliminated_locations << report.location
          else
            open_locations << report.location
          end
          locations << report.location
        elsif params[:view] == 'open' && report.status == :reported
          reports_with_status_filtered << report
          open_locations << report.location
        elsif params[:view] == 'eliminate' && report.status == :eliminated
          reports_with_status_filtered << report
          eliminated_locations << report.location
        end
      end
    end
    
    # @map_json = locations.map { |location| {"lat" => location.latitude, "lng" => location.longitude} }.to_json

    @markers = locations.map { |location| location.info}
    @open_markers = open_locations.map { |location| location.info}
    @eliminated_markers = eliminated_locations.map { |location| location.info}
    @reports = reports_with_status_filtered
    @counts = Report.group(:location_id).count
    @open_counts = Report.where(status_cd: 0).group(:location_id).count
    @eliminated_counts = Report.where(status_cd: 1).group(:location_id).count
    @open_feed = @reports
    @eliminate_feed = @reports
  end
  
  def new
    @report = Report.new
  end

  def create    

    if request.post?
      address = params[:street_type].downcase.titleize + " " + params[:street_name].downcase.titleize + " " + params[:street_number].downcase.titleize
      flash[:street_type] = params[:street_type]
      flash[:street_name] = params[:street_name]
      flash[:street_number] = params[:street_number]
      flash[:description] = params[:report][:report]
      flash[:x] = params[:x]
      flash[:y] = params[:y]
      location = Location.find_by_address(address)
      
      if params[:x].empty? or params[:y].empty?
        flash[:alert] = "Você precisa marcar uma localização válida para o seu foco."
        redirect_to :back
        return
      end

      if location.nil?
        location = Location.new(:street_type => params[:street_type].downcase.titleize, :street_name => params[:street_name].downcase.titleize, :street_number => params[:street_number].downcase.titleize, latitude: params[:x], longitude: params[:y])
      else
        location.latitude = params[:x]
        location.longitude = params[:y]
      end

      location.save
      
      if params[:report][:report] == ""
        flash[:alert] = "Você tem que descrever o local e/ou o foco."
        flash[:address] = address
        @report = Report.new(:location => location)
        redirect_to :back
        return
      end

      if !params[:report][:before_photo] and params[:report]
        flash[:alert] = "Você tem que carregar uma foto do foco encontrado."  
        @report = Report.new(:location => location)
        @report.report = params[:report][:report]
        redirect_to :back
        return
      end



      @report = Report.create_from_user("", :status => :reported, :reporter => @current_user, :location => location)
      @report.report = params[:report][:report]
      
      @report.completed_at = Time.now
      @report.before_photo = params[:report][:before_photo]
    
      if @report.save
        if @current_user != nil and params[:before_photo]
          # @current_user.update_attribute(:points, @current_user.points + 100)
        end
        
        flash[:notice] = 'Foco marcado com sucesso!'
        redirect_to :action=>'index', view: 'recent'
      else
        flash[:alert] = "here"
        redirect_to :back
      end
    end
  end
  
  def edit
    @report = @current_user.created_reports.find(params[:id])
    flash[:street_type] = @report.location.street_type
    flash[:street_name] = @report.location.street_name
    flash[:street_number] = @report.location.street_number
    flash[:x] = @report.location.latitude
    flash[:y] = @report.location.longitude
    @report.location.latitude ||= 0
    @report.location.longitude ||= 0
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
        response = 'username: ' + params[:From].delete('+') + ' Temporary password: ' + password + ' To login to the site, go to http://www.denguetorpedo.com' 
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
      @report = Report.find_by_id(params[:report_id])

      if @report.sms_incomplete?


        if !(params[:street_type] != "" && params[:street_name] != "" && params[:street_number] != "")
          flash[:alert] = "Você precisa endereço válida para o seu foco."
          redirect_to :back
          return
        end

        if params[:x].to_i == 0.0 || params[:y].to_i == 0.0
          flash[:alert] = "Você precisa marcar uma localização válida para o seu foco."
          redirect_to :back
          return
        end

        if !params[:report][:before_photo]
          flash[:alert] = "Você tem que carregar uma foto do foco encontrado."  
          redirect_to :back
          return
        end

        if params[:x] and params[:y]

          address = params[:street_type].downcase.titleize + " " + params[:street_name].downcase.titleize + " " + params[:street_number].downcase.titleize

          location = Location.find_by_address(address)

          if location.nil?
            location = Location.new(:street_type => params[:street_type].downcase.titleize, :street_name => params[:street_name].downcase.titleize, :street_number => params[:street_number].downcase.titleize, latitude: params[:x], longitude: params[:y])
            location.save
          else
            location.update_attributes(latitude: params[:x], longitude: params[:y])

          end
          @report.location = location
        else
          flash[:alert] = "Você precisa marcar uma localização válida para o seu foco."
          redierct_to :back
          return
        end

        @report.report = params[:report][:report]
        if params[:report][:before_photo]
          @report.before_photo = params[:report][:before_photo]
        end

        if @report.save
          @report.update_attributes(completed_at: Time.now)
          flash[:notice] = "Foco completado com sucesso!"
          redirect_to reports_path
        else
          flash[:alert] = "There was an error completing your report!"
          redirect_to :back
        end
        return
      end



      @report = Report.find(params[:report_id])

      if params[:elimination_type] == ""
        flash[:error] = "Você tem que escolher um tipo de foco."
        redirect_to :back
        return
      end

      if @report.elimination_type.nil? and params[:elimination_type]
        @report.elimination_type = params[:elimination_type]
        @report.completed_at = Time.now
        @report.save
        flash[:notice] = "Tipo de foco atualizado com sucesso."
        @current_user.update_attribute(:points, @current_user.points + 50)
        @current_user.update_attribute(:total_points, @current_user.total_points + 50)
        redirect_to :back
        return
      end
 
      if params[:report_description]
        @report.report = params[:report_description]
        @report.save
      end
      
      if !params[:eliminate] and @report.after_photo_file_size.nil?
        flash[:error] = 'Você tem que carregar uma foto do foco eliminado.'
        redirect_to(:back)
        return
      end

      if params[:selected_elimination_method] == ""

        if @report.after_photo_file_size.nil?
          if params[:eliminate] and params[:eliminate][:after_photo] != nil
          # user uploaded an after photo
            @report.after_photo = params[:eliminate][:after_photo]
            @current_user.points += 400
            @current_user.total_points += 400
            @current_user.save
            @report.save
          end
        end

        flash[:error] = "Você tem que escolher um método de eliminação."
        redirect_to :back
        return
      end
      
      if @report.after_photo_file_size.nil?
        if params[:eliminate] and params[:eliminate][:after_photo] != nil 
          # user uploaded an after photo
          @report.after_photo = params[:eliminate][:after_photo]
          @current_user.points += 400
          @current_user.total_points += 400
          @current_user.save
          @report.save
        end
      end

      if !params[:eliminate]

        @report.update_attribute(:status_cd, 1)
        @report.update_attribute(:eliminator_id, @current_user.id)
        # @report.elimination_type = params[:elimination_type]
        @report.elimination_method = params[:selected_elimination_method]
        @report.touch(:eliminated_at)
        @report.save
        flash[:notice] = "Você eliminou o foco!"
        redirect_to reports_path
        return
      end

                         
      if params[:eliminate][:after_photo] != nil
        # user uploaded an after photo
        begin
          @report.after_photo = params[:eliminate][:after_photo]
          @report.update_attribute(:status_cd, 1)
          @report.update_attribute(:eliminator_id, @current_user.id)
          @report.touch(:eliminated_at)
          @current_user.points += 400
          @current_user.total_points += 400
          @current_user.save
        rescue
          flash[:notice] = 'An error has occurred!'
          redirect_to(:back)
          return
        end
        
        # @report.elimination_type = EliminationMethods.getEliminationTypeFromMethodSelect(params["method_of_elimination"])
        # @report.elimination_method = params["method_of_elimination"]
        # @report.elimination_type = params[:elimination_type]
        @report.elimination_method = params[:selected_elimination_method]
        
        if @report.save
          flash[:notice] = 'Você eliminou o foco!'
          redirect_to(:back)
        else
          #for some reason save causes error here, but in view it looks OK
          flash[:notice] = 'An error has occurred'
          redirect_to(:back)
        end
      
      elsif params[:eliminate][:before_photo] != nil
        # user uploaded a before photo
        @report.before_photo = params[:eliminate][:before_photo]
        @current_user.points += 100
        @current_user.total_points += 100
        @current_user.save
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
    # @current_user.created_reports.find(params[:id]).destroy

    if @current_user.admin? or @current_user.created_reports.find_by_id(params[:id])
      Report.find(params[:id]).destroy
      flash[:notice] = "Foco deletado com sucesso."
    end

    redirect_to(:back)
  end

  def verify
    @report = Report.find(params[:id])

    if @report.status_cd == 1
      @report.is_resolved_verified = true
      @report.resolved_verifier_id = @current_user.id
      @report.resolved_verified_at = DateTime.now
    elsif @report.status_cd == 0
      @report.isVerified = true
      @report.verifier_id = @current_user.id
      @report.verified_at = DateTime.now
    end
    
    if @report.save
      flash[:notice] = "O foco foi verificado."
      redirect_to reports_path
    else
      redirect_to :back
    end
  end

  def problem
    @report = Report.find(params[:id])

    if @report.status_cd == 1
      @report.is_resolved_verified = false
      @report.resolved_verifier_id = @current_user.id
      @report.resolved_verified_at = DateTime.now
      @report.resolved_verifier.points -= 100
      @report.resolved_verifier.save
    elsif @report.status_cd == 0
      @report.isVerified = false
      @report.verifier_id = @current_user.id
      @report.verified_at = DateTime.now
      @report.verifier.points -= 100
      @report.verifier.save
    end
    if @report.save
      flash[:notice] = "O foco foi verificado."
      redirect_to reports_path
    else
      redirect_to :back
    end
  end

  def torpedos
    @user = User.find(params[:id])
    @reports = @user.reports.sms.where('is_credited IS NULL OR is_credited = ?', true)
  end

  def gateway
    @user = User.find_by_phone_number(params[:from])
    respond_to do |format|
      if @user
        if @user.residents?
          @report = @user.report_by_phone(params)
          if @report.save
            Notification.create(board: "5521981865344", phone: params[:from], text: "Parabéns! O seu relato foi recebido e adicionado ao Dengue Torpedo.")
            format.json { render json: { message: "success", report: @report}}
          else
            Notification.create(board: "5521981865344", phone: params[:from], text: "Nós não pudemos adicionar o seu relato porque houve um erro no nosso sistema.")
            format.json { render json: { message: @report.errors.full_messages}, status: 401}
          end
        else
          Notification.create(board: "5521981865344", phone: params[:from], text: "O seu perfil não está habilitado para o envio do Dengue Torpedo.")
          format.json { render json: { message: "Sponsors or verifiers"}, status: 401}
        end
      else
        Notification.create(board: "5521981865344", phone: params[:from], text: "Você ainda não tem uma conta. Registre-se no site do Dengue Torpedo.")
        format.json { render json: { message: "There is no registered user with the given phone number."}, status: 404}
      end
    end
  end

  def notifications
    @notifications = Notification.unread
    @notifications.each { |notification| notification.read = true; notification.save }
    respond_to do |format|
      format.json { render json: @notifications }
    end
  end

  def creditar
    respond_to do |format|
      if @report.creditar
        format.js
      else
        format.json { render json: { message: "failure"}, status: 401 }
      end
    end
  end

  def credit
    respond_to do |format|
      if @report.credit
        format.js
      else
        format.json { render json: {message: "failure"}, status: 401}
      end
    end
  end

  def discredit
    respond_to do |format|
      if @report.discredit
        format.js
      else
        format.json { render json: {message: "failure"}, status: 401}
      end
    end
  end

  private
  def find_by_id
    @report = Report.find(params[:id])
  end
end
