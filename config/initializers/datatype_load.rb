class Datatypehelper

  DATATYPE_COLLECTION = [
                         Datatype.new(1, "text"),
                         Datatype.new(2, "year"),
                         Datatype.new(3, "date"),
                         Datatype.new(5, "category"),
                         Datatype.new(7, "number"),
                         Datatype.new(8, "unknown")
                        ]
  UNKNOWN = DATATYPE_COLLECTION.detect {|dt| dt.name == 'unknown'}

  def self.known
    DATATYPE_COLLECTION.reject{|dt| dt.name == 'unknown'}
  end

  def self.find_by_name(name)
    return UNKNOWN if name.blank?
    name = name.downcase.strip
    DATATYPE_COLLECTION.each{ |dt| return dt if dt.name == name }
    return UNKNOWN
  end

  def self.find_by_id(id)
    DATATYPE_COLLECTION.each{ |dt| return dt if dt.id == id }
    return UNKNOWN
  end
end