class Datatypehelper

  DATATYPE_COLLECTION = [
                         Datatype.new(1, "text", ""),
                         Datatype.new(2, "year", ""),
                         Datatype.new(3, "date", "yyyy-mm-dd"),
                         Datatype.new(5, "category", ""),
                         Datatype.new(7, "number", ""),
                         Datatype.new(8, "unknown", "")
                        ]

  def self.known
    DATATYPE_COLLECTION.reject{|dt| dt.name == 'unknown'}
  end
  
  def self.find_by_name(name)
    DATATYPE_COLLECTION.each{ |dt| return dt if dt.name == name }
    return find_by_name('unknown')
  end

  def self.find_by_id(id)
    DATATYPE_COLLECTION.each{ |dt| return dt if dt.id == id }
    return find_by_id(8)
  end
end