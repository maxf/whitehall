class FatalityNotice < Announcement
  include Edition::RoleAppointments
  include Edition::FactCheckable
  include Tire::Model::Search

  tire.index_name 'whitehall_announcement_search'
  mapping do
    indexes :id,                    index: :not_analyzed
    indexes :title,                 analyzer: 'snowball', boost: 4
    indexes :summary,               analyzer: 'snowball', boost: 2
    indexes :indexable_content,     analyzer: 'snowball'
    indexes :state,                 analyzer: 'keyword'
    indexes :timestamp_for_sorting, type: 'date'
    indexes :first_published_at,    type: 'date'
    indexes :organisations,         type: 'string',
                                    analyzer: 'keyword',
                                    as: 'organisations.map(&:id)'
    indexes :topics,                type: 'string',
                                    analyzer: 'keyword',
                                    as: 'topics.map(&:id)'
  end

  belongs_to :operational_field

  class CasualtiesTrait < Edition::Traits::Trait
    def process_associations_after_save(new_edition)
      @edition.fatality_notice_casualties.each do |casualty|
        new_edition.fatality_notice_casualties.create(casualty.attributes.except(:id))
      end
    end
  end

  has_many :fatality_notice_casualties, dependent: :destroy

  accepts_nested_attributes_for :fatality_notice_casualties, allow_destroy: true, reject_if: :all_blank

  validates :operational_field, :roll_call_introduction, presence: true

  add_trait CasualtiesTrait

  def has_operational_field?
    true
  end
end
