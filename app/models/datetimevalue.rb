class Datetimevalue < ActiveRecord::Base

  has_many :sheetcells, :as => :value

  def show_value
    txt = []
    txt << date unless date.nil?
    txt << year unless year.nil?
    txt << month unless month.nil?
    txt << day unless day.nil?
    #TODO HACK?
    txt = txt.to_sentence #(:connector => "")
    # month, day is still missing
    "#{txt}"
  end

end
