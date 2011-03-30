module PaperproposalsHelper
  def author_list_formatter(author_list)
    corresponding = author_list[:corresponding]
    string = "<p>"

    author_string_array = []
    author_list[:author_list].each do |author|
     author_string = "#{author.to_label}"
     author_string = author_string + "*" if author == corresponding
     author_string_array << author_string
    end
    string << author_string_array.join(", ")


    unless author_list[:ack].empty?
      string << "</p><p>"
      string <<  "Acknowledgment: "
      author_list[:ack].each do |author|
        string << "#{author.to_label}"
        string << ", "
      end
      string << "</p>"
    end
    string << "</p>"
    return string
  end

end
