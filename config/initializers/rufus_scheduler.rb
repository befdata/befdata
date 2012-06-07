require 'rufus/scheduler'

scheduler = Rufus::Scheduler.start_new



scheduler.every '20s' do
   datasets_to_regenerate_download = Dataset.where("updated_at >= '#{(Time.now - 2.hours - 10.minutes).to_s(:db)}'
                                                    AND updated_at >= download_generated_at
                                                    AND download_generation_status = 'finished'")

   #datasets = Dataset.where("download_generation_status = 'finished OR download_generation_status = ''")


  datasets_to_regenerate_download.each do |dataset|
    dataset.enqueue_to_generate_download
    puts "enqueed dataset #{dataset.id}"
  end
end

