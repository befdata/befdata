desc 'copy files from test_data_files to files directory'
task 'cp_datafiles' do
  test_data_files = File.join(Rails.root, 'test', 'fixtures', 'test_data_files/*')
  FileUtils.cp_r Dir.glob(test_data_files), File.join(Rails.root, 'files')
end

namespace :db do
  namespace :fixtures do
    task 'load' => :environment do
      Rake::Task['cp_datafiles'].invoke
    end
  end
end