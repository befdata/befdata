xml.instruct!
xml.keywords do
  @tags.each do |t|
    xml.keyword(id: t.id) do
      xml.id t.id
      xml.name t.name
      xml.count t.count
    end
  end
end
