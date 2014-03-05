class ExportedCsv < ExportedFile

  has_attached_file :file, :path => ":rails_root/files/generated/:dataset_id_generated-download.csv"

  def format
    'csv'
  end

  def export
    self.update_attribute(:status, STARTED)

    tf = Tempfile.new("csv-#{dataset_id}-temp")

    # gather columns and values
    all_columns = []
    dataset.datacolumns.order("columnnr ASC").each do |dc|
      column = []
      column[0] = dc.columnheader

      dc.sheetcells.find_each do |sc|
        column[sc.row_number - 1] = sc.export_value
      end
      all_columns << column
    end

    # bring to same length to transpose
    max_length = all_columns.map{|c| c.length}.max
    all_columns.each{|c|   c[max_length-1] = nil unless c.length == max_length}
    all_columns  = all_columns.transpose

    CSV.open tf, mode='w' do |csv|
      all_columns.each {|c| csv << c}
    end

    self.file = tf
    self.file_file_name = dataset.title.gsub(/[^\w]/, '-')
    self.generated_at = Time.now
    self.status = FINISHED
    puts "=== Download generated for Dataset id: #{dataset_id}.#{format} at #{Time.now}"
    save
  end
end
