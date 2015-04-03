module ApplicationHelper
  #----------------------------------------------------------------------------

  def chart_cookies
    return {} if cookies[:chart].blank?
    return JSON.parse(cookies[:chart])
  end

  #----------------------------------------------------------------------------

  def blog_post_award_text
    return "+ #{User::Points::POST_CREATED.to_s} " + I18n.t("attributes.points").downcase
  end

  #----------------------------------------------------------------------------

  def logo_image
    if I18n.locale.to_s == User::Locales::PORTUGUESE
      image_tag("logo_pt.png", :id => "logo")
    else
      image_tag("logo_es.png", :id => "logo")
    end
  end

  #----------------------------------------------------------------------------

  def self.temp_password_generator
    char_bank = ('0'..'9').to_a
    char_bank.shuffle.shuffle.shuffle!
    (1..8).collect{|a| char_bank[rand(char_bank.size)] }.join
  end

  #----------------------------------------------------------------------------

  def timestamp_in_metadata(timestamp)
    return "" if timestamp.blank?
    if (timestamp - Time.now).abs < 3.days
      time_ago_in_words(timestamp) + " " + I18n.t("common_terms.ago")
    else
      return timestamp.strftime("%Y-%m-%d %H:%M")
    end
  end

  #----------------------------------------------------------------------------

  def format_timestamp(timestamp)
    return "" if timestamp.blank?
    return timestamp.strftime("%Y-%m-%d %H:%M")
  end

  #----------------------------------------------------------------------------

  def display_as_icon(boolean)
    if boolean
      return "<i class = 'fa fa-check' />".html_safe
    else
      return "<i class = 'fa fa-close' />".html_safe
    end
  end

end
