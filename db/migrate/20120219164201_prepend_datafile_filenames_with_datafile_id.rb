class PrependDatafileFilenamesWithDatafileId < ActiveRecord::Migration
  def self.up
    filepath = File.join(Rails.root, 'files')

    Datafile.all.each do |df|
      f_old = File.join filepath, df.file_file_name
      f_new = File.join filepath, "#{df.id}_#{df.file_file_name}"

      if File.exist?(f_new) && File.file?(f_new)
        puts "Filename already migrated: #{f_new}"

      elsif File.exist?(f_old) && File.file?(f_old)
        puts "renaming: #{f_old} > #{f_new}"
        puts File.rename(f_old, f_new)

      else
        puts "either nonexistent or no file: #{f_old}"
      end
    end
  end

  def self.down
  end
end
