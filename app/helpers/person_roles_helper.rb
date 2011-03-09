module PersonRolesHelper
  #content field is shown in FCK editor format
  def comment_form_column(record, input_name)
    fckeditor_textarea(:record, :comment, :toolbarSet => 'Simple', :name=> input_name, :width => "900px", :height => "600px" )
  end

  #content text is displayed in rich format
  def comment_column(record)
    sanitize(record.comment)
  end
end
