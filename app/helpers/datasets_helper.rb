module DatasetsHelper
  def content_tag_unless_blank(tag, content)
    content_tag_string(tag, content, nil) unless content.blank?
  end

  def eml_unit_for_column(column)
    case column.unit
      when 'meter' || 'm'
        "meter"
      when 'millimeter' || 'mm'
        "millimeter"
      when 'gram' || 'g'
        "gram"
      #when 'gramsPerSquareMeter' || 'g/m^2' || 'g/m²'
      else
        "dimensionless"
    end
  end
end
