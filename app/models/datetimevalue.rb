## The class "Datetimevalue" contains date values. It is one of
## the tables fitting in the "Value_type" and "Value_id" in the table
## with all the measurements (Measurement). The other possibles entry types are
## Numericvalue,  Categoricvalue, PersonRole, and Textvalue

class Datetimevalue < ActiveRecord::Base
  has_many :measurements, :as => :value

  def show_value
    txt = []
    txt << date unless date.nil?
    txt << year unless year.nil?
    txt << month unless month.nil?
    txt << day unless day.nil?
    txt = txt.to_sentence(:connector => "")
    # month, day is still missing
    "#{txt}"
  end

end
