require 'rufus/scheduler'

scheduler = Rufus::Scheduler.start_new



scheduler.cron '* * * * *' do  #once a minute

  #generation of download only every ten minutes -> download_generated_at < Time.now - 10.minutes
  #generation if updates since last generation -> updated_at >= download_generated_at
  #only for downloads which are not currently being processed -> status = nil or finished
  only_every_ten_minutes = "download_generated_at <= '#{(Time.now.utc - 10.minutes).to_s(:db)}' "
  if_updated_after_last_generation = "AND updated_at >= download_generated_at "
  if_download_generation_is_not_in_progress = "AND download_generation_status = 'finished'"
  datasets = Dataset.where(only_every_ten_minutes +
                                if_updated_after_last_generation +
                                if_download_generation_is_not_in_progress)

  datasets.each do |dataset|
    dataset.enqueue_to_generate_download
    puts "enqueed dataset #{dataset.id}"
  end
end

