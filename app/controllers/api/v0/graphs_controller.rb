# -*- encoding : utf-8 -*-
include GreenLocationWeeklySeries

class API::V0::GraphsController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token

  #----------------------------------------------------------------------------
  # GET /api/v0/graph/timeseries

  def timeseries
    # Determine the timeframe based on timeframe OR custom date ranges.
    if params[:custom_start_month].present? || params[:custom_start_year].present?
      start_month = params[:custom_start_month] || "01"
      start_year  = params[:custom_start_year]  || "2010"
      start_time  = Time.zone.parse("#{start_year}-#{start_month}-01")
    end

    if params[:custom_end_month].present? || params[:custom_end_year].present?
      end_month = params[:custom_end_month] || "12"
      end_year  = params[:custom_end_year]  || Time.zone.now.year
      end_days  = Time.days_in_month(end_month.to_i)
      end_time  = Time.zone.parse("#{end_year}-#{end_month}-#{end_days}")
    end

    # In case there were no custom start ranges, then let's rely on timeframe.
    if start_time.blank?
      if params[:timeframe].nil? || params[:timeframe] == "-1"
        start_time = nil
      else
        start_time = params[:timeframe].to_i.months.ago
      end
    end

    neighborhoods = []
    params[:neighborhoods].split(",").each do |nparams|
      neighborhoods << Neighborhood.find_by_id(nparams)
    end
    location_ids = neighborhoods.map {|n| n.locations.pluck(:id)}.flatten.uniq

    if params[:unit] == "daily"
      statistics = Visit.calculate_time_series_for_locations(location_ids, start_time, end_time, "daily")
    else
      statistics = Visit.calculate_time_series_for_locations(location_ids, start_time, end_time, "monthly")
    end

    statistics.each do |shash|
      locations = Location.where(:id => shash[:locations]).pluck(:address)
      shash[:locations] = locations
    end

    render :json => statistics.as_json, :status => 200 and return
  end


  #----------------------------------------------------------------------------
  # GET /api/v0/graph/locations
  # Parameters:
  # * timeframe (required),
  # * percentages (required),
  # * neighborhood_id (optional).

  def locations
    neighborhood    = Neighborhood.find_by_id(params[:neighborhood_id])

    # Determine the timeframe based on timeframe OR custom date ranges.
    if params[:custom_start_month].present? || params[:custom_start_year].present?
      start_month = params[:custom_start_month] || "01"
      start_year  = params[:custom_start_year]  || "2010"
      start_time  = Time.zone.parse("#{start_year}-#{start_month}-01")
    end

    if params[:custom_end_month].present? || params[:custom_end_year].present?
      end_month = params[:custom_end_month] || "12"
      end_year  = params[:custom_end_year]  || Time.zone.now.year
      end_days  = Time.days_in_month(end_month.to_i)
      end_time  = Time.zone.parse("#{end_year}-#{end_month}-#{end_days}")
    end

    # In case there were no custom start ranges, then let's rely on timeframe.
    if start_time.blank?
      if params[:timeframe].nil? || params[:timeframe] == "-1"
        start_time = nil
      else
        start_time = params[:timeframe].to_i.months.ago
      end
    end

    selected_location_ids = JSON.parse(params[:location_ids]) if params[:location_ids].present?
    if selected_location_ids.present?
      visit_ids = selected_location_ids
      locations = Location.where(:id => selected_location_ids)
    elsif params[:csv_only].present?
      locations = neighborhood.locations.where("locations.id IN (SELECT location_id FROM csv_reports)")
      visit_ids = locations.pluck(:id)
    else
      locations = neighborhood.locations
      visit_ids = locations.pluck(:id)
    end
    locations = locations.order("address ASC")


    # Finally, let's check to see if this request is coming from the public neighborhood page.
    # If it is, then we need to limit the end_time be end of the next-to-last month to
    # account for lag in uploading CSVs.
    if params[:display] == "public" && end_time.blank?
      end_time = (Time.zone.now.beginning_of_month - 2.months).end_of_month
    end

    if params[:percentages] == "daily"
      statistics = Visit.calculate_time_series_for_locations(visit_ids, start_time, end_time, "daily")
    else
      statistics = Visit.calculate_time_series_for_locations(visit_ids, start_time, end_time, "monthly")
    end

    statistics.unshift([I18n.t('views.statistics.chart.time'), I18n.t('views.statistics.chart.percent_of_positive_sites'), I18n.t('views.statistics.chart.percent_of_potential_sites'), I18n.t('views.statistics.chart.percent_of_negative_sites')])

    # Update the cookies.
    if cookies[:chart].present?
      settings = JSON.parse(cookies[:chart])
      settings = params.slice(:timeframe, :percentages, :type, :positive, :potential, :negative)
      settings[:timeframe]   ||= "3"
      settings[:percentages] ||= "daily"
      settings[:type]        ||= "bar"
      settings[:positive]    ||= "1"
      settings[:potential]   ||= "1"
      settings[:negative]    ||= "1"

      cookies[:chart] = settings.to_json
    end

    render :json => {:data => statistics.as_json, :locations => locations.as_json}, :status => 200 and return
  end

  #----------------------------------------------------------------------------
  # GET /api/v0/graph/green_locations

  def green_locations
    city = City.find(params[:city])

    end_time   = Time.zone.now.end_of_week
    start_time = end_time - 6.months
    @series = GreenLocationWeeklySeries.time_series_for_city(city, start_time, end_time)

    # We will pad empty data with green locations = 0.
    while start_time < end_time
      if @series.find {|s| s[:date].strftime("%Y%W") == start_time.end_of_week.strftime("%Y%W")}.blank?
        @series << {:date => start_time.end_of_week, :green_houses => 0}
      end

      start_time += 1.week
    end

    @series.sort_by! {|s| s[:date]}

    render "api/v0/graph/green_locations"
  end

end
