# -*- encoding : utf-8 -*-
# An inspection is a conceptual connection between a visit and some breeding site.
# In other words, a visit has many breeding sites through some inspection.
#
# NOTE: The primary key is (report_id, visit_id).
# NOTE: Inspection times are defined in the associated report.
class Inspection < ActiveRecord::Base
  attr_accessible :visit_id, :report_id, :csv_id, :identification_type, :position, :report, :pupae, :created_at, :neighborhood_id, :breeding_site_id,
  :elimination_method_id, :before_photo, :after_photo, :status, :reporter_id,
  :location, :location_attributes, :breeding_site, :eliminator_id, :verifier_id,
  :location_id, :reporter, :sms, :is_credited, :credited_at, :completed_at,
  :verifier, :resolved_verifier, :eliminator, :eliminated_at, :csv_report_id,
  :protected, :chemically_treated, :larvae, :field_identifier, :description, :previous_similar_inspection_id

  module Types
    POSITIVE  = 0
    POTENTIAL = 1
    NEGATIVE  = 2
  end


  #----------------------------------------------------------------------------
  # Constants

  EXPIRATION_WINDOW = 48 * 3600 # in seconds


  # This is the minimum time threshold that we allow between created_at and
  # eliminated_at.
  ELIMINATION_THRESHOLD = 1.minute


  #----------------------------------------------------------------------------
  # PaperClip configurations
  #-------------------------

  has_attached_file :before_photo,
  :default_url => 'default_images/report_before_photo.png', :styles => {
    :large => ["450x450>", :jpg],
    :medium => "300x300>"
  }, :convert_options => { :medium => "-quality 75 -strip", :large => "-quality 75 -strip" }

  has_attached_file :after_photo,
  :default_url => 'default_images/report_after_photo.png', :styles => {
    :large => ["450x450>", :jpg],
    :medium => "300x300>"
  }, :convert_options => { :medium => "-quality 75 -strip", :large => "-quality 75 -strip" }

  attr_accessor :save_without_before_photo
  attr_accessor :save_without_after_photo
  attr_accessor :save_without_elimination_method

  #----------------------------------------------------------------------------
  # Associations
  #-------------

  belongs_to :location
  belongs_to :breeding_site
  belongs_to :elimination_method

  belongs_to :visit
  belongs_to :report
  belongs_to :spreadsheet, :foreign_key => "csv_id"

  # The following associations define all stakeholders in the sing
  # process.
  belongs_to :reporter,          :class_name => "User"
  belongs_to :eliminator,        :class_name => "User"
  belongs_to :verifier,          :class_name => "User"
  belongs_to :resolved_verifier, :class_name => "User"
  belongs_to :spreadsheet, :foreign_key => "csv_id"
  belongs_to :previous_similar_inspection, class_name: "Inspection"

  has_many :likes, :as => :likeable, :dependent => :destroy

  alias_attribute :prepared_at, :completed_at


  #----------------------------------------------------------------------------
  # Validations
  #-------------
  # TODO :report validation fails unexpectedly:
  # * When creating a new report and a user doesn't submit a picture, he'll get an error to add a picture
  # * After adding a picture if the user tries to submit again they'll get an error about having to provide
  #  a description. Despite the fact that the description field in filled AND the model object shows it as not being blank
  validates :location_id,      :presence => true
  #validates :description,      :presence => true
  validates :reporter_id,      :presence => true
  # validates :breeding_site_id, :presence => true
  # validates :elimination_method_id, :presence => {:on => :update}, :unless => Proc.new {|file| self.save_without_elimination_method == true}

  # validates :before_photo,     :presence => {:on => :create}, :unless => Proc.new {|file| self.save_without_before_photo == true}
  # validates :after_photo,           :presence => {:on => :update}, :unless => Proc.new {|file| self.save_without_after_photo == true}
  validates_attachment :before_photo, content_type: { content_type: /\Aimage\/.*\Z/ }, :unless => Proc.new {|file| self.save_without_before_photo == true}
  validates_attachment :after_photo,  content_type: { content_type: /\Aimage\/.*\Z/ }, :unless => Proc.new {|file| self.save_without_after_photo == true}

  # validate :created_at,    :inspected_in_the_past?
  # validate :created_at,    :inspected_after_two_thousand_fourteen?
  # validate :eliminated_at, :eliminated_after_creation?
  # validate :eliminated_at, :eliminated_in_the_past?

  scope :displayable, -> { where("larvae = ? OR pupae = ? OR protected = ? OR protected IS NULL", true, true, false) }
  scope :completed,   -> { where("verified_at IS NOT NULL") }
  scope :incomplete,  -> { where("verified_at IS NULL") }
  scope :eliminated,  -> { where("eliminated_at IS NOT NULL AND elimination_method_id IS NOT NULL") }
  scope :is_open,        -> { where("eliminated_at IS NULL OR elimination_method_id IS NULL") }

  scope :similar_inspections_by_id, lambda { |inspection_id| joins(:previous_similar_inspection).where("inspections.previous_similar_inspection_id = ?", inspection_id)}


  #----------------------------------------------------------------------------

  after_destroy :conditionally_destroy_visit

  def self.humanized_inspection_types
    {
      Types::POSITIVE  => "Positivo",
      Types::POTENTIAL => "Potencial",
      Types::NEGATIVE  => "Negativo"
    }
  end

  def self.color_for_inspection_status
    {
      Inspection::Types::POSITIVE  => "#e74c3c",
      Inspection::Types::POTENTIAL => "#f1c40f",
      Inspection::Types::NEGATIVE  => "#2ecc71"
    }
  end

  #----------------------------------------------------------------------------

  def conditionally_destroy_visit
    visit = Visit.find_by_id(self.visit_id)
    visit.destroy if visit && visit.inspections.count == 0
  end

  #----------------------------------------------------------------------------

  # This method returns the report's original status, which is the status
  # that the report had when it was first created.
  def original_status
    return Inspection::Types::POSITIVE if (self.larvae || self.pupae)
    return Inspection::Types::NEGATIVE if (self.protected)
    return Inspection::Types::POTENTIAL
  end


  # NOTE: We have to use this hack (even though Paperclip handles base64 images)
  # because we want to explicitly specify the content type and filename. Some
  # of this is taken from
  # https://github.com/thoughtbot/paperclip/blob/master/lib/paperclip/io_adapters/data_uri_adapter.rb
  # and
  # https://gist.github.com/WizardOfOgz/1012107
  def self.base64_image_to_paperclip(base64_image, filename = nil)
    regexp = /\Adata:([-\w]+\/[-\w\+\.]+)?;base64,(.*)/m
    data_uri_parts = base64_image.match(regexp) || []
    data = StringIO.new(Base64.decode64(data_uri_parts[2] || ''))
    data.class_eval do
      attr_accessor :content_type, :original_filename
    end
    data.content_type = "image/jpeg"
    data.original_filename = filename || SecureRandom.base64 + ".jpg"

    return data
  end

  #----------------------------------------------------------------------------

  def breeding_site_picture
    if self.before_photo_file_name.nil?
      return nil
    end

    return self.before_photo.url(:medium)
  end

  #----------------------------------------------------------------------------

  def elimination_method_picture
    if self.after_photo_file_name.nil?
      return nil
    end

    return self.after_photo.url(:medium)
  end

  #----------------------------------------------------------------------------

  def reporters
    assignments = Assignment.joins(:city_block).where("city_blocks.name LIKE ? AND date::date = ?", self.location.address[0..4], self.inspected_at.beginning_of_day)
    reporters = []
    #if !self.reporter.nil?
    #  reporters << self.reporter
    #end
    assignments.each do |assignment|
      assignment.users.each do |user|
        reporters << user
      end
    end
    return reporters.uniq{ |r| r.id }
  end

  #----------------------------------------------------------------------------

  def eliminated?
    return (self.eliminated_at.present? && self.elimination_method_id.present?)
  end

  def open?
    return (self.eliminated_at.blank? || self.elimination_method_id.blank?)
  end

  def verified?
    return self.verified_at.present?
  end

  #----------------------------------------------------------------------------

  def get_previous_similar_inspection
    last_similar = Inspection.joins(:location, :visit).where("inspections.breeding_site_id = ? and locations.address = ? and visits.visited_at < ?", self.breeding_site_id, self.location.address, self.visit.visited_at).order("visits.visited_at DESC").first rescue nil
    unless last_similar.blank?
      self.previous_similar_inspection = last_similar
      self.save
    end
  end

  def self.get_all_previous_similar_inspections
    Inspection.all.each do |ins|
      ins.get_previous_similar_inspection
    end
  end

  #----------------------------------------------------------------------------

  private

  # Since the CSV report doesn't encode the *time of day*, we
  # end up with a situation where an initial report and an elimination report
  # will have the same 'created_at/eliminated_at' timestamp. To remedy this, we will
  # check to see if the 2 columns match. If they do, then we will
  # set the difference to be the threshold.
  def set_elimination_threshold
    return true if self.created_at.blank?
    return true if self.eliminated_at.blank?

    self.eliminated_at += ELIMINATION_THRESHOLD if (self.created_at - self.eliminated_at).abs < ELIMINATION_THRESHOLD
  end

  #------------------
  # Validator helpers
  #------------------

  def eliminated_after_creation?
    return true if self.eliminated_at.blank?

    # If the report hasn't been created yet, then let's compare elimination time
    # to the current time. Otherwise, let's compare to the time of creation.
    if self.created_at.blank?
      return true if self.eliminated_at >= Time.zone.now
    else
      # NOTE: We need to check for equality in case some records had their dates
      # set to beginning of day (before we were handling time of day).
      return true if self.eliminated_at >= self.created_at
    end

    created_at = I18n.t("activerecord.attributes.report.created_at") || "inspection date"
    self.errors[:eliminated_at] << "can't be before " + created_at.downcase
    return false
  end

  def inspected_in_the_past?
    return true if self.created_at.blank?
    return true if self.created_at.past?

    self.errors[:created_at] << "can't be in the future"
    return false
  end

  def inspected_after_two_thousand_fourteen?
    return true if self.created_at.blank?
    return true if self.created_at.year >= 2014

    self.errors[:created_at] << "can't be before 2014"
    return false
  end

  def eliminated_in_the_past?
    return true if self.eliminated_at.blank?
    return true if self.eliminated_at.past?

    self.errors[:eliminated_at] << "can't be in the future"
    return false
  end

  #----------------------------------------------------------------------------

end
