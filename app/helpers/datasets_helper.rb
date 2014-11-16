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
      when 'gramsPerSquareMeter' || 'g/m^2'
      else
        "dimensionless"
    end
  end

  def may_see_comment?(dataset = @dataset)
    return false unless current_user
    return true if current_user.has_role? :admin
    return true if current_user.has_role? :project_board
    return true if dataset.accepts_role? :owner, current_user
    false
  end

  def dropdown_list_to_sort_datasets
    options_for_select(
      { "Title" => 'title-asc',
        "Newest" => 'id-desc',
        "Recently Updated" => 'updated_at-desc'
      }, selected: "#{params[:sort]}-#{params[:direction]}")
  end
end
