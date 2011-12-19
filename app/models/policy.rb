class Policy < Document
  include Document::NationalApplicability
  include Document::PolicyAreas
  include Document::Ministers
  include Document::FactCheckable
  include Document::SupportingPages
  include Document::Countries

  has_many :document_relations, foreign_key: :policy_id
  has_many :related_documents, through: :document_relations, source: :document
  has_many :published_related_documents, through: :document_relations, source: :document, conditions: { "documents.state" => "published" }

  class Trait < Document::Traits::Trait
    def process_associations_after_save(document)
      document.related_documents = @document.related_documents
    end
  end

  add_trait Trait
end