## The Datatype class is the validated data type for the "Sheetcell" accepted_value. Datatypes are initialised at application start up by the "Datatypehelper" class.
##
## See config/initializers/datatype_load.rb ( DatattypeLoad ) for initializing datatypes
## and a list of possible datatypes. A Datagroup contains a datatype attribute that is a suggestion 
## for the datatype attribute of a Datacolumn. Datacolumn overrides Datagroup. After validation, a 
## Datacolumn may have different datatypes, since invalid values are converted to Category objects.
## Validation is performed by PostgreSQL procedures defined in db/non_schema_sql.sql
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