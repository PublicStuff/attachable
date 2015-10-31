module Attachable
  extend ActiveSupport::Concern

  def self.included(base)
    base.class_eval do
      has_many :attachments, as: :attachable, autosave: true
      has_many :files, through: :attachments, source: :file_ref

      validate :check_attachments, :on => :create

      accepts_nested_attributes_for :attachments

      def self.has_attachments flag = true
        if flag
          self.where("#{self.table_name}.attachments_count > 0")
        else
          self.where("#{self.table_name}.attachments_count = 0")
        end
      end

      #
      # Handle nested attributes
      # TODO: This function overrides nested attributes defaults to support
      # make internal.  This should be abstracted to support more functionality
      # and for more objects
      #
      alias :original_attachments_attributes= :attachments_attributes=
      def attachments_attributes=(attrs)
        self.original_attachments_attributes = attrs
        self.attachments.each do |attachment|
          if !attachment.persisted? and attrs[0][:make_internal]
            attachment.internalize self.client
          end
        end
      end
    end
  end

  def supported_file_types
    return FileRef.supported_extensions_flat
  end

  def supports_file_type?(file_type)
    return (self.supported_file_types.empty? or self.supported_file_types.include?(file_type.downcase))
  end

  def max_files_allowed?
    return -1
  end

  def max_file_size?
    return -1
  end

  private
  def check_attachments
    self.attachments.each do |attachment|
      if !self.supports_file_type?(attachment.file_ref.extension)
        errors.add(:extension, "#{attachment.file_ref.extension} is not supported")
      end
    end

    # TODO: check file size

    if (max_files_allowed? > -1 and self.attachments.size >= max_files_allowed?)
      errors.add(:max_files, "Max files allowed reached")
    end
  end
end

module ImageAttachable
  include Attachable

  def supported_file_types
    return FileRef.supported_extensions[:photo];
  end
end
