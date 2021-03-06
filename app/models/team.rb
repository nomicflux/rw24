require "acts_as_list"

class Team < ActiveRecord::Base
  def self.allowed_ranges
    {
      :a_team       => 2..6,
      :b_team       => 2..6,
      :b_team       => 2..6,
      :elder_team   => 2..6,
      :solo_male    => 1..1,
      :solo_female  => 1..1,
      :solo_elder   => 1..1,
      :tandem       => 2..2,
      :tandem_elder => 2..2,
    }
  end

  def self.categories
    ["A Team", "B Team", "Elder Team", "Solo (male)", "Solo (female)", "Solo (elder)", "Tandem", "Tandem (elder)"]
  end

  default_scope -> { order(:position) }
  
  def self.by_category category
    where(category: category)
  end

  attr_accessor :phone

  belongs_to :site
  belongs_to :race
  has_many :riders, :dependent => :delete_all
  has_many :points

  accepts_nested_attributes_for :riders, :reject_if => lambda { |attrs| attrs["name"].blank? }

  validates_presence_of :race, :name, :category
  validates_uniqueness_of :position, :scope => :race_id
  validates_each :riders do |record, attr, value|
    record.errors.add attr, 'count is incorrect.' unless record.allowed_range.include? value.length
  end

  acts_as_list :scope => :race_id

  before_save :assign_phone_to_captain, :assign_site

  def self.leader_board
    includes(:points).sort do |a,b|
      comp = a.points_total <=> b.points_total
      comp == 0 ? a.position <=> b.position : comp
    end.reverse
  end

  def self.send_confirmation_email_by_ids team_ids
    Team.where(id: team_ids).each do |team|
      team.delay.send_confirmation_email!
    end
  end

  def send_confirmation_email!
    Mailer.confirmation_email(self).deliver
    update_attribute :confirmation_sent_at, Time.now
  end

  def initialize *options, &block
    options[0] ||= {}
    options[0].reverse_merge! "category" => "A Team"
    super
  end

  def laps_total
    points.laps.sum(:qty)
  end

  def miles_total
    laps_total * BigDecimal.new("4.6")
  end

  def bonuses_total
    points.bonuses.sum(:qty)
  end

  def penalties_total
    points.penalties.sum(:qty)
  end

  def points_total
    points.sum(:qty)
  end

  def allowed_range
    self.class.allowed_ranges[category.parameterize.underscore.to_sym]
  end

  def captain
    riders.first
  end

  def captain_email
    captain.email
  end

  def lieutenants
    riders - [captain]
  end

  def lieutenant_emails
    lieutenants.collect(&:email).select(&:present?).join(", ")
  end

  def shirt_sizes
    riders.collect(&:shirt).join(", ")
  end

  def category_abbrev
    category[0..0] if category
  end

  def category_abbrev_with_gender
    return category_abbrev unless category_abbrev == "S"
    category =~ /female/ ? "F" : "M"
  end

  def position_and_name
    "#{position} - #{name}"
  end

  def paid?
    riders.all?(&:paid?)
  end

  def partially_paid?
    not paid? and riders.any?(&:paid)
  end

  def emailed?
    confirmation_sent_at.present?
  end

  def to_paypal_hash
    {
      :no_shipping => "1",
      :business => "riverwest24@gmail.com",
      :amount => 20.00,
      :quantity => riders.length,
      :item_name => "Riverwest 24 Registration - #{category}",
      :cmd => "_xclick",
      :custom => id,
      :return => "http://riverwest24.com/join/articles/thanks",
      :notify_url => "http://riverwest24.com/join/registrations/payment",
      :shopping_url => "http://riverwest24.com",
      :cancel_return => "http://riverwest24.com",
      :upload => "1",
      :currency_code => "USD",
      :no_note => "1",
      :address_override => "1"
    }
  end

  private

  def assign_phone_to_captain
    captain.phone = self.phone if self.phone
  end

  def assign_site
    self.site = Site.first
  end
end
