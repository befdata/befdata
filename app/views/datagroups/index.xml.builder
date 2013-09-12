xml.instruct!
xml.datagroups {
  @datagroups.each do |dg|
    xml.datagroup(id: dg.id) {
      xml.id dg.id
      xml.title dg.title
      xml.description dg.description
      xml.columns_count dg.datacolumns_count
      xml.categories_count dg.categories_count
    }
  end
}