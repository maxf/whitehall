module Attachable
  extend ActiveSupport::Concern

  module ClassMethods
    def attachable(class_name)
      self.attachment_join_table_name = "#{class_name}_attachments".to_sym

      has_many attachment_join_table_name, foreign_key: "#{class_name}_id", dependent: :destroy
      has_many :attachments, through: attachment_join_table_name

      no_substantive_attachment_attributes = ->(attrs) do
        att_attrs = attrs.fetch(:attachment_attributes, {})
        att_attrs.except(:accessible, :attachment_data_attributes).values.all?(&:blank?) &&
          att_attrs.fetch(:attachment_data_attributes, {}).values.all?(&:blank?)
      end
      accepts_nested_attributes_for attachment_join_table_name, reject_if: no_substantive_attachment_attributes, allow_destroy: true

      if respond_to?(:add_trait)
        add_trait do
          def process_associations_after_save(edition)
            @edition.attachments.each do |a|
              attachment = Attachment.create(a.attributes)
              edition.send(edition.class.attachment_join_table_name).create(attachment: attachment)
            end
          end
        end
      end
    end
    def force_review_of_bulk_attachments
      include Attachable::ForceReviewOfBulkAttachments
    end
  end

  module ForceReviewOfBulkAttachments
    extend ActiveSupport::Concern

    included do
      attr_accessor :attachments_were_bulk_uploaded
      attr_accessor :bulk_upload_zip_file_invalid

      validate :force_review_if_attachments_were_bulk_uploaded
      validate :bulk_upload_zip_file_must_be_valid
    end

    def force_review_if_attachments_were_bulk_uploaded
      errors.add(:information, 'Bulk upload successful: Make sure you check all the metadata is correct before saving') unless self.attachments_were_bulk_uploaded.nil?
    end

    def bulk_upload_zip_file_must_be_valid
      errors.add(:base, 'Bulk upload failed: The Zip file was invalid') unless self.bulk_upload_zip_file_invalid.nil?
    end
  end

  included do
    class_attribute :attachment_join_table_name
  end

  def build_empty_attachment
    attachment_join_model_instances = send(self.class.attachment_join_table_name)
    unless attachment_join_model_instances.any?(&:new_record?)
      join_model_instance = attachment_join_model_instances.build
      attachment_instance = join_model_instance.build_attachment
      attachment_instance.build_attachment_data
    end
  end

  def allows_attachments?
    true
  end

  def allows_attachment_references?
    false
  end

  def allows_inline_attachments?
    true
  end

  def has_thumbnail?
    thumbnailable_attachments.any?
  end

  def thumbnail_url
    thumbnailable_attachments.first.url(:thumbnail)
  end

  def thumbnailable_attachments
    attachments.select {|a| a.content_type == AttachmentUploader::PDF_CONTENT_TYPE}
  end

  def indexable_content
    (super + " " + indexable_attachment_content).strip
  end

  private

  def indexable_attachment_content
    attachments.all.map { |a| "Attachment: #{a.title}" }.join(". ")
  end

  module JoinModel
    extend ActiveSupport::Concern

    module ClassMethods
      def attachable_join_model_for(class_name)
        belongs_to :attachment, dependent: :destroy
        belongs_to class_name

        accepts_nested_attributes_for :attachment, reject_if: :all_blank
      end
    end
  end
end
