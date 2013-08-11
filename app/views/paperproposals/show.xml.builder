xml.instruct!
xml.paperproposal(id: @paperproposal.id) {
  xml.title @paperproposal.title
  xml.rationale @paperproposal.rationale
  xml.createdAt @paperproposal.created_at
  xml.status @paperproposal.board_state
  xml.project @paperproposal.authored_by_project, id: @paperproposal.project_id
  xml.proposer {
    xml.person(id: @paperproposal.author_id) {
      xml.name @paperproposal.author
      xml.email @paperproposal.author.email
    }
  }
  xml.proponents {
    @paperproposal.proponents.each do |u|
      xml.person(id: u.id) {
        xml.name u
        xml.email u.email
      }
    end
  }
  xml.datasets {
    @paperproposal.dataset_paperproposals.each do |dspp|
      dataset = dspp.dataset
      xml.dataset(id: dataset.id) {
        xml.title dataset.title
        xml.aspect dspp.aspect
        xml.authorizable dataset.can_download_by? current_user
        xml.owners {
          dataset.owners.each do |u|
            xml.person(id: u.id) {
              xml.name u
              xml.email u.email
            }
          end
        }
        xml.urls {
          xml.xls download_dataset_url(dataset, user_credentials: current_user.try(:single_access_token))
          xml.csv download_dataset_url(dataset, format: :csv, separate_category_columns: true, user_credentials: current_user.try(:single_access_token))
        }
      }
    end
  }
  xml.envisaged {
    xml.journal @paperproposal.envisaged_journal
    xml.date @paperproposal.envisaged_date
    xml.state @paperproposal.state
  }
}

