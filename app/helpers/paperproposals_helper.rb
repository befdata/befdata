module PaperproposalsHelper
  def author_list_formatter(author_list)
    corresponding = author_list[:corresponding]
    string = "<p>"
    author_list[:author_list].each do |author|
     string << "#{author.to_label}"
     string << "*" if author == corresponding
     string << ", "
    end

    unless author_list[:ack].empty?
      string << "</p><p>"
      string <<  "Acknowledgment: "
      author_list[:ack].each do |author|
        string << "#{author.to_label}"
        string << ", "
      end
      string << "</p>"
    end
    return string
  end

end
