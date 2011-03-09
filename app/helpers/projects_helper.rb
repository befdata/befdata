module ProjectsHelper
  def description_form_column(record, input_name)
    fckeditor_textarea(:record, :description, :toolbarSet => 'Simple', :name=> input_name, :width => "900px", :height => "600px" )
  end

  def description_column(record)
    sanitize(record.description)
  end

  def funding_form_column(record, input_name)
    fckeditor_textarea(:record, :funding, :toolbarSet => 'Simple', :name=> input_name, :width => "900px", :height => "600px" )
  end

  def funding_column(record)
    sanitize(record.funding)
  end

  def comment_form_column(record, input_name)
    fckeditor_textarea(:record, :comment, :toolbarSet => 'Simple', :name=> input_name, :width => "900px", :height => "600px" )
  end

  def comment_column(record)
    sanitize(record.comment)
  end
end
