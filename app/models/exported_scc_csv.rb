class ExportedSccCsv < ExportedFile

  has_attached_file :file, :path => ":rails_root/files/generated/:dataset_id_generated-download_scc.csv"

  def format
    'csv2'
  end

  def export
    self.update_attribute(:status, STARTED)

    tf = Tempfile.new("scc-csv-#{dataset_id}-temp")

    # gather columns and values
    all_columns = []
    dataset.datacolumns.order("columnnr ASC").each do |dc|
      column = []
      category_column = []
      column[0] = dc.columnheader
      category_column[0] = "#{dc.columnheader}_Categories"

      ExportedSheetcell.uncached do
        dc.exported_sheetcells.find_each do |sc|
          if dc.import_data_type == 'category' || !sc.is_category
            column[sc.row_number - 1] = sc.export_value
          else
            category_column[sc.row_number - 1] = sc.export_value
          end
        end
      end
      all_columns << column
      all_columns << category_column if category_column.length > 1
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
