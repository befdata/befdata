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

  def may_download_dataset?(dataset = @dataset)
    return false unless dataset.upload_spreadsheet

    return true if dataset.free_for_public
    return false unless current_user

    return true if dataset.free_for_members || current_user.has_role?(:admin) || current_user.has_role?(:data_admin) || current_user.has_role?(:owner, dataset)
    return true if current_user.has_role?(:proposer, dataset)
    return true if dataset.free_within_projects && !(current_user.projects & dataset.projects).empty?
    false
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
      {"Title" => data_path(params.merge(sort: 'title', direction: 'asc')),
        "Newest" => data_path(params.merge(sort: 'id', direction: 'desc')),
        "Recently Updated" => data_path(params.merge(sort: 'last_update', direction: 'desc'))
      }, selected: data_path(params))
  end
end
