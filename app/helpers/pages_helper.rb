module PagesHelper
  #content field is shown in FCK editor format
  def content_form_column(record, input_name)
    fckeditor_textarea(:record, :content, :toolbarSet => 'Simple', :name=> input_name, :width => "900px", :height => "600px" )
  end

  #content text is displayed in rich format
  def content_column(record)
    sanitize(record.content)
  end
end
