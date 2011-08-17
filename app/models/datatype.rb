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