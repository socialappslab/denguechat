#!/bin/env ruby
# encoding: utf-8


class CsvReportsController < NeighborhoodsBaseController
  before_filter :require_login

  #----------------------------------------------------------------------------
  # GET /neighborhoods/1/csv_reports

  def index
    @csv_reports = @current_user.csv_reports.order("updated_at DESC")

    @visits              = @csv_reports.includes(:location).map {|r| r.location}.compact.uniq
    @total_locations     = @visits.count
    @statistics = Visit.calculate_time_series_for_locations(@visits)
    @table_statistics = @statistics.last
    @chart_statistics = @statistics.map {|hash|
      [
        hash[:date],
        hash[:positive][:percent],
        hash[:potential][:percent],
        hash[:negative][:percent],
        hash[:clean][:percent]
      ]
    }

    @statistics = Visit.calculate_time_series_for_locations(@visits)


    @last_statistics = []
    legend = [I18n.t("views.statistics.table.positive_sites"), I18n.t("views.statistics.table.potential_sites"),
    I18n.t("views.statistics.table.negative_sites"), I18n.t("views.statistics.table.clean_sites")]
    if @statistics.present?
      [:positive, :potential, :negative, :clean].each_with_index do |key, index|
        @last_statistics << [legend[index], @statistics.last[key][:count]]
      end
    end

  end


  #----------------------------------------------------------------------------
  # GET /neighborhoods/1/csv_reports/new

  def new
    @csv_report = CsvReport.new
  end

  #----------------------------------------------------------------------------
  # POST /neighborhoods/1/csv_reports

  # We assume the user will upload a specific CSV (or .xls, .xlsx) template.
  # Once uploaded, we parse the CSV and assign a UUID to each row which
  # will be saved with a new report (if it's ever created).
  # If a report exists with the UUID, then we update that report instead of
  # creating a new one.
  def create
    @csv_report = CsvReport.new

    # 1. Ensure that the location has been identified on the map.
    lat  = params[:report_location_attributes_latitude]
    long = params[:report_location_attributes_longitude]
    if lat.blank? || long.blank?
      flash[:alert] = I18n.t("views.csv_reports.flashes.missing_location")
      render "new" and return
    end

    # 2. Identify the file content type.
    file        = params[:csv_report][:csv]
    spreadsheet = load_spreadsheet( file )
    unless spreadsheet
      flash[:alert] = I18n.t("views.csv_reports.flashes.unknown_format")
      render "new" and return
    end

    # NOTE: We assume the location is not negative unless otherwise noted, and
    # there is no last inspection date to correspond with the clean location.
    is_location_clean    = false
    last_inspection_date = nil
    reports        = []
    visits         = []
    parsed_content = []


    # 3. Identify the start of the reports table in the CSV file.
    # The first row is reserved for the house location/address.
    # Second row is reserved for permission.
    address = spreadsheet.row(1)[1]
    if address.blank?
      flash[:alert] = I18n.t("views.csv_reports.flashes.missing_house")
      render "new" and return
    end
    address = address.to_s

    # The start index is essentially the number of rows that are occupied by
    # location metadata (including address, permission to record, etc)
    start_index = 3
    while spreadsheet.row(start_index)[0].to_s.downcase.exclude?("fecha de visita")
      start_index += 1
    end
    header  = spreadsheet.row(start_index)
    header.map! { |h| h.to_s.downcase.strip.gsub("?", "").gsub(".", "").gsub("¿", "") }


    # 4. Parse the CSV.
    # The CSV is laid out to define the house number (or address)
    # on the first row, and then the following template for the table:
    # [
    #   "fecha de visita (aaaa-mm-dd)",
    #   "tipo de criadero",
    #   "localización",
    #   "protegido",
    #   "abatizado",
    #   "larvas",
    #   "pupas",
    #   "foto de criadero",
    #   "eliminado (aaaa-mm-dd)",
    #   "foto de eliminación",
    #   "comentarios sobre tipo y/o eliminación*"
    # ]
    current_row   = 0
    current_visit = nil

    (start_index + 1..spreadsheet.last_row).each do |i|
      row            = Hash[[header, spreadsheet.row(i)].transpose]
      parsed_content << row
      current_row   += 1

      # 4a. Extract the attributes. NOTE: We use fuzzy matching instead of
      # exact matching since users may vary the columns slightly.
      date           = row.select {|k,v| k.include?("fecha de visita")}.values[0].to_s
      room           = row["localización"].to_s
      type           = row.select {|k,v| k.include?("tipo")}.values[0].to_s
      is_protected   = row['protegido'].to_i
      is_pupas       = row["pupas"].to_i
      is_larvas      = row["larvas"].to_i
      is_chemical     = row["abatizado"].to_i
      elim_date      = row.select {|k,v| k.include?("fecha de eliminac")}.values[0].to_s
      comments       = row.select {|k,v| k.include?("comentarios")}.values[0].to_s


      # 4b. Attempt to identify the breeding sites from the codes. If no type
      # is identified, then simply skip the whole row.
      next if type.blank?

      type = type.strip.downcase
      if ["a", "b", "l", "m", "p", "t", "x", "n"].include?( type )
        if type == "a"
          breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::DISH)
        elsif type == "b"
          breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::LARGE_CONTAINER)
        elsif type == "l"
          breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::TIRE)
        elsif type == "m"
          breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::DISH)
        elsif type == "p"
          breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::LARGE_CONTAINER)
        elsif type == "t"
          breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::SMALL_CONTAINER)
        end
      else
        flash[:alert] = I18n.t("views.csv_reports.flashes.unknown_code")
        render "new" and return
      end

      # 4c. Define the description based on the collected attributes.
      description = ""
      description += "Localización: #{room}" if room.present?
      description += ", Protegido: #{is_protected}, Abatizado: #{is_chemical}, Larvas: #{is_larvas == 1 ? "si" : "no"}, Pupas: #{is_pupas == 1 ? "si" : "no"}"
      description += ", Comentarios sobre tipo y/o eliminación: #{comments}" if comments.present?

      # 4d. Generate a UUID to identify the row that the report will correspond
      # to. We define the UUID based on
      # * House location,
      # * Date of visit,
      # * The room within the house,
      # * Type of site,
      # * Properties identified at the site.
      # If there is a match, then we simply update the existing report.
      uuid = (address + date + room + type + is_protected.to_s + is_pupas.to_s + is_larvas.to_s + is_chemical.to_s)
      uuid = uuid.strip.downcase.underscore

      if type && type != "n"
        reports << {
          :inspection_date  => date,
          :elimination_date => elim_date,
          :breeding_site    => breeding_site,
          :description      => description,
          :protected        => is_protected, :chemically_treated => is_chemical, :larvae => is_larvas, :pupae => is_pupas,
          :csv_uuid         => uuid
        }
      end

      # Finally, let's create a location status, if appropriate. We do
      # this by comparing the new visit date with the current one.
      if date.present? && current_visit != date
        puts "current_visit: #{current_visit} | date = #{date}"
        current_visit = date

        # Let's parse the reporting on chik and dengue.
        disease_report = row.select {|k,v| k.include?("reporte")}.values[0].to_s
        disease_report = nil if disease_report.blank?
        # if disease_report.present?
        #   chik_count   = /([0-9]*)c/.match(disease_report)
        #   chik_count   = chik_count[1].to_i if chik_count.present?
        #   dengue_count = /([0-9]*)d/.match(disease_report)
        #   dengue_count = dengue_count[1].to_i if dengue_count.present?
        # end

        # Now let's see if the location is clean.
        # If the last type is n, then the location is clean (for now).
        # If it's not the last row, then we simply label the status as a potential
        # breeding site. The actual status will be updated when the associated
        # report's create callback is invoked.
        if i.to_i == spreadsheet.last_row.to_i && type && type.strip.downcase == "n"
          status = Visit::Types::NEGATIVE
        else
          status = Visit::Types::POTENTIAL
        end

        # Now let's try parsing the date.
        visit_date = Time.zone.parse(date)
        visit_date = Time.now if visit_date.blank?

        visits << {
          :date => visit_date, :health_report => disease_report, :status => status
        }

      end
    end

    # 5. Error out if there are no reports extracted.
    if current_row == 0
      flash[:alert] = I18n.t("views.csv_reports.flashes.missing_visits")
      render "new" and return
    end

    # 6. Find and/or create the location.
    location = Location.find_by_address(address)
    if location.blank?
      location = Location.create!(:latitude => lat, :longitude => long, :address => address)
    end

    # Now that we have a location, let's update the Visit.
    # Note that if the reports that will be reported after this have any
    # positive status, then the location will be treated updated accordingly.
    # NOTE: The reports will be associated with these visits thanks to the report's
    # callback hook.
    visits.each do |visit|
      ls = Visit.where(:location_id => location.id)
      ls = ls.where(:identified_at => (visit[:date].beginning_of_day..visit[:date].end_of_day) ).order("identified_at DESC")
      if ls.blank?
        ls = Visit.new(:location_id => location.id)
        ls.identified_at = visit[:date]
      else
        ls = ls.first
      end

      ls.identification_type  = visit[:status]
      ls.health_report        = visit[:health_report]
      ls.save
    end


    # 7. Create or update the CSV file.
    # TODO: For now, we simply create a new CSV file everytime it's uploaded.
    # In the future, we want to search out CSV reports to see if any/all report
    # UUID match those that were parsed here.
    @csv_report.csv            = file
    @csv_report.parsed_content = parsed_content.to_json
    @csv_report.user_id        = @current_user.id
    @csv_report.location_id    = location.id
    @csv_report.save!

    Analytics.track( :user_id => @current_user.id, :event => "Created a CSV report") if Rails.env.production?

    # 8. Create or update the reports.
    # NOTE: We set completed_at to nil in order to signify that the user
    # has to update the report.
    reports.each do |report|
      r = Report.find_by_csv_uuid(report[:csv_uuid])

      if r.blank?
        r = Report.new

        # Note: We're overriding the created_at and updated_at dates in order
        # to more closely reflect the correct site identification time.
        # Also, note that we *must* set updated_at to same as created_at in order
        # for the set_location_status method to correctly update the Visit
        # instance to the right date (which is the date of house inspection).
        parsed_inspection_date = Time.zone.parse( report[:inspection_date] )
        if parsed_inspection_date.blank?
          puts "\n\n\n [Error] Could not parse inspection date = #{report[:inspection_date]}...\n\n\n"
        else
          r.created_at = parsed_inspection_date
          r.updated_at = parsed_inspection_date
        end

        Analytics.track( :user_id => @current_user.id, :event => "Created a new report", :properties => {:source => "CSV"}) if Rails.env.production?
      end

      # Note: We're overriding the eliminated_at column in order to allow
      # Nicaraguan community members to have more control over their reports.
      elimination_date = Time.zone.parse( report[:elimination_date] )
      if elimination_date.blank?
        puts "\n\n\n [Error] Could not parse elimination date = #{report[:elimination_date]}...\n\n\n"
      else
        r.eliminated_at = elimination_date
      end

      r.report             = report[:description]
      r.breeding_site_id   = report[:breeding_site].id if report[:breeding_site].present?
      r.protected          = report[:protected]
      r.chemically_treated = report[:chemically_treated]
      r.larvae             = report[:larvae]
      r.pupae              = report[:pupae]
      r.location_id        = location.id
      r.neighborhood_id    = @neighborhood.id
      r.reporter_id        = @current_user.id
      r.csv_report_id      = @csv_report.id
      r.csv_uuid           = report[:csv_uuid]
      r.save(:validate => false)
    end

    # At this point, let's celebrate.
    flash[:notice] = I18n.t("views.csv_reports.flashes.create")
    redirect_to neighborhood_reports_path(@neighborhood) and return
  end

  #----------------------------------------------------------------------------


  private

  #----------------------------------------------------------------------------

  def load_spreadsheet(file)
    if File.extname( file.original_filename ) == ".csv"
      spreadsheet = Roo::CSV.new(file.tempfile.path, :file_warning => :ignore)
    elsif File.extname( file.original_filename ) == ".xls"
      spreadsheet = Roo::Excel.new(file.tempfile.path, :file_warning => :ignore)
    elsif File.extname( file.original_filename ) == ".xlsx"
      spreadsheet = Roo::Excelx.new(file.tempfile.path, :file_warning => :ignore)
    end

    return spreadsheet
  end

  #----------------------------------------------------------------------------

end
