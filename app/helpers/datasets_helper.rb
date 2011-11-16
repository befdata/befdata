module DatasetsHelper
  def content_tag_unless_blank(tag, content)
    "<#{tag}>#{content}</#{tag}>" unless content.blank?
  end
end
