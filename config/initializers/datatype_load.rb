class Datatypehelper

  DATATYPE_COLLECTION = [
                         Datatype.new(1, "text", ""),
                         Datatype.new(2, "year", ""),
                         Datatype.new(3, "date", "yyyy-mm-dd"),
                         Datatype.new(5, "category", ""),
                         Datatype.new(7, "number", ""),
                         Datatype.new(8, "unknown", "")
                        ]

  # This method returns all known datatypes (i.e. all datatypes except 'unknown').
  def self.known
    DATATYPE_COLLECTION.reject{|dt| dt.name == 'unknown'}
  end
  
  # A little helper method to extract a datatype from the collection by name
  def self.find_by_name(name)
    found = nil
    
    # Look up the given name in the collection
    DATATYPE_COLLECTION.each{ |dt| found = dt if dt.name == name }
      
    # Fallback for the event of not finding a datatype for this name
    found = DATATYPE_COLLECTION.select{|dt| dt.name == 'unknown'}.shift unless found
      
    return found
  end

  # A little helper method to extract a datatype from the collection by id
  def self.find_by_id(id)
    found = nil
    
    # Look up the given id in the collection
    DATATYPE_COLLECTION.each{ |dt| found = dt if dt.id == id }

    # Fallback for the event of not finding a datatype for this id
    found = DATATYPE_COLLECTION.select{|dt| dt.id == 8}.shift unless found

    return found
  end
end