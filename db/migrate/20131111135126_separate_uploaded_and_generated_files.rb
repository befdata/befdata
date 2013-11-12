class SeparateUploadedAndGeneratedFiles < ActiveRecord::Migration
  def up
    uploaded_dir, generated_dir = %w{uploaded generated}.collect { |d| File.join(Rails.root, 'files', d) }

    [uploaded_dir, generated_dir].each do |dir|
      FileUtils.mkdir_p dir unless File.directory? dir
    end

    Datafile.has_attached_file :file, :basename => "basename", :path => ":rails_root/files/:id_:filename"
    Dataset.has_attached_file :generated_spreadsheet, :path => ":rails_root/files/:id_generated-download.xls"

    Datafile.where('file_file_name is not NULL and dataset_id is not NULL').find_each do |df|
      FileUtils.mv df.file.path, File.join(uploaded_dir, File.basename(df.file.path)) if File.file? df.file.path
    end

    Dataset.where('generated_spreadsheet_file_name is not NULL').find_each do |dt|
      original_path = dt.generated_spreadsheet.path
      FileUtils.mv original_path, File.join(generated_dir, File.basename(original_path)) if File.file? original_path
    end
  end

  def down
    files_dir = File.join(Rails.root, 'files')

    %w{uploaded generated}.each do |dir|
      FileUtils.mv Dir.glob(File.join(files_dir, dir, '*.*')), files_dir
    end
  end
end
