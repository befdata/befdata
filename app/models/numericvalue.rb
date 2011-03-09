## The class "Numericvalue" contains numeric values. It is one of
## the tables fitting in the "Value_type" and "Value_id" in the table
## with all the measurements (Measurement). The other possibles entry types are
## Categoricvalue,  Datetimevalue, PersonRole, and Textvalue
class Numericvalue < ActiveRecord::Base

  has_many :measurements, :as => :value

  before_destroy :check_for_measurements

  def check_for_measurements
    puts "in check for measurements"
    val = self.reload
    puts "Number of measurements linked:"
    puts val.measurements.length.to_s
    unless val.measurements.length == 0
      puts "measurements linked"
      errors.add_to_base "Cannot destroy value with Data Cells associations"
      false
    end
  end

  def show_value
    "#{number.round(3)}"
  end

end
