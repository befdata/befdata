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

  def paperproposal_state_to_i(paperproposal = @paperproposal)
    case paperproposal.board_state
      when 'prep', 're_prep' then 1
      when 'submit' then 2
      when 'data_rejected' then 3
      when 'accept' then 4
      when 'final' then 5
      else 0
    end
  end

  def compare_progress_class(elements_state_number, paperproposal = @paperproposal)
    case elements_state_number <=> paperproposal_state_to_i(paperproposal)
      when -1 then 'state-less'
      when 0 then 'state-equal'
      when 1 then 'state-greater'
    end
  end

  def proposal_is_accepted?
    return false unless @paperproposal
    @paperproposal.state == 'accepted'
  end

  def is_paperproposal_author?
    return false unless @paperproposal && current_user
    @paperproposal.author == current_user
  end

  def author_may_edit?
    is_paperproposal_author? && @paperproposal.lock == false
  end

  def author_may_edit_datasets?
    author_may_edit? && @paperproposal.board_state != 'final'
  end

  def may_administrate_paperproposals?
    return false unless current_user
    current_user.has_role?(:admin) || current_user.has_role?(:data_admin)
  end

end
