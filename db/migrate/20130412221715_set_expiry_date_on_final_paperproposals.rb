class SetExpiryDateOnFinalPaperproposals < ActiveRecord::Migration
  def up
    in_two_years = Date.today + 2.years
    Paperproposal.where("board_state = 'final' AND expiry_date IS NULL").each do |pp|
      pp.update_attribute(:expiry_date, in_two_years)
      puts "Paperproposal #{pp.id}: expiry date is now #{pp.expiry_date}"
    end
  end

  def down
    # This migration can not be reverted
  end
end
