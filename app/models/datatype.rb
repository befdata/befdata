## The Datatype class is the validated data type for the "Sheetcell" accepted_value. Datatypes are initialised at application start up by the "Datatypehelper" class.
##
## The possible Datatypes are text, year, number, category, date(2009-07-14) and date(14.07.2009).
class Datatype
  attr_accessor :id, :name, :format

  def initialize(id, name, format)
    @id = id
    @name = name
    @format = format
  end

  def to_s
    @name
  end

  def is_category?
    return (@name == "category")
  end

end