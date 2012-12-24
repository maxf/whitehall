class StatisticalDataSet < Publicationesque
  include Edition::DocumentSeries
  include Edition::AlternativeFormatProvider
  include Tire::Model::Search

  tire.index_name 'whitehall_publication_search'
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
                                    as: 'organisations.map(&:topics).flatten.map(&:id)'
  end

  def allows_attachment_references?
    true
  end

  def self.access_limited_by_default?
    true
  end
end
