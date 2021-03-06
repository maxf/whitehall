class OrganisationType < ActiveRecord::Base
  validates :name, presence: true, uniqueness: true

  LISTING_ORDER = [
    "Ministerial department",
    "Non-ministerial department",
    "Executive agency",
    "Executive non-departmental public body",
    "Advisory non-departmental public body",
    "Tribunal non-departmental public body",
    "Public corporation",
    "Independent monitoring body",
    "Ad-hoc advisory group",
    "Sub-organisation",
    "Other"
  ]

  def self.in_listing_order
    all.sort_by { |ot| ot.listing_order }
  end

  def self.unlistable
    sub_organisation
  end

  def self.sub_organisation
    where(name: "Sub-organisation")
  end

  def self.agency_or_public_body
    where(arel_table[:name].not_eq("Sub-organisation"))
  end

  def listing_order
    LISTING_ORDER.index(name)
  end

  def ministerial_department?
    name == "Ministerial department"
  end

  def department?
    name =~ /\bdepartment\b/i
  end

  def self.departmental_types
    all.select { |t| t.department? }
  end

  def sub_organisation?
    name == "Sub-organisation"
  end
end
