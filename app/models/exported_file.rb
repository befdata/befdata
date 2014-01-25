class ExportedFile < ActiveRecord::Base
  belongs_to :dataset

  after_create {|record| record.queued_to_be_exported }

  STATUS = [NEW = 'new', QUEUED = 'queued', STARTED = 'started', FINISHED = 'finished'].freeze
  scope :outdated, -> { where('invalidated_at > generated_at and status = ? ', 'finished')}

  TYPES = {
      csv: 'ExportedCsv',
      csv2: 'ExportedSccCsv',
      xls: 'ExportedExcel'
  }.freeze

  scope :with_format, lambda { |type|
    raise 'Unvalid format' unless TYPES.has_key? type.to_sym
    where(type: TYPES[type.to_sym])
  }

  validates_inclusion_of :status, :in => STATUS, :on => :update
  validates_uniqueness_of :type, :scope => :dataset_id, :case_sensitive => false

  delegate :path, :to => :file, :allow_nil => true

  # allow to use :dataset_id in file path
  Paperclip.interpolates :dataset_id do |attachment, style|
    attachment.instance.dataset_id
  end

  # creates 3 exported files(csv, csv2, xls) for a given dataset
  def self.initialize_export(dataset)
    return false unless dataset.has_research_data? and dataset.finished_import?
    TYPES.each do |name, type|
      type.classify.constantize.where(dataset_id: dataset.id).first_or_create
    end
  end

  # marks exported file(s) as invalidate by touching the invalidated_at timestamp
  # acceted values for formats are: :all, :csv, :csv2, :xls. other values are ignored.
  def self.invalidate(dataset_id, *formats)
    if formats.empty? or formats == [:all]
      types = TYPES.values
    else
      types = TYPES.slice(*formats).values
    end
    return false if types.empty?

    ExportedFile.where(dataset_id: dataset_id, type: types).update_all(invalidated_at: Time.now)
    true
  end

  # collects all stale exported files and queues them to be regenerated
  def self.regenerate_downloads_for_outdated_files
    stale_files = ExportedFile.outdated.where("invalidated_at < ?", 10.minutes.ago.to_s(:db))

    stale_files.each do |ef|
      ef.queued_to_be_exported
      puts "queued dataset #{ef.dataset_id}, format: #{ef.format}"
    end
  end

  def queued_to_be_exported(priority = :low)
    priority = 10 if priority.eql?(:low)
    priority = 0 if priority.eql?(:high)

    return unless dataset.finished_import? # Only export after it's been imported
    return if status.eql?('queued') # don't queue it twice

    self.update_attribute(:status, 'queued')
    self.delay(:priority => priority).export
  end

  # redefine the getter method of status field
  def status
    stored_status = read_attribute(:status)
    return 'outdated'.inquiry if stored_status == 'finished' && invalidated_at > generated_at
    return stored_status.inquiry
  end

  def outdated?
    status.outdated?
  end

  def invalidate!
    touch :invalidated_at
  end
end
