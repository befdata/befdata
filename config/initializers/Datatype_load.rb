class Datatypehelper

  DATATYPE_COLLECTION = [
                         Datatype.new(1, "text", ""),
                         Datatype.new(2, "year", ""),
                         Datatype.new(3, "date(2009-07-14)", "yyyy.mm.dd"),
                         Datatype.new(4, "date(14.07.2009)", "dd.mm.yyyy"),
                         Datatype.new(5, "category", ""),
                         Datatype.new(7, "number", "")
                        ]


  def self.find_by_name(name)
    found = nil
    DATATYPE_COLLECTION.each { |dt|
      found = dt if dt.name == name
    }
    found

  end

  def self.find_by_id(id)
    found = nil
    DATATYPE_COLLECTION.each { |dt|
      found = dt if dt.id == id
    }
    found

  end

end