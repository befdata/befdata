xml.instruct!
xml.dataset(:id => @dataset.id) {
  if @dataset.visible_for_public || current_user
    xml.title  @dataset.title
    xml.abstract @dataset.abstract
    xml.taxonomicextent @dataset.taxonomicextent
    xml.spatialextent @dataset.spatialextent
    xml.temporalextent {
      xml.begin @dataset.datemin
      xml.end  @dataset.datemax
    }
    xml.design @dataset.design
    xml.uploaded_at @dataset.created_at
    xml.authors {
      @contacts.each do |u|
        xml.author(id: u.id) {
          xml.name u.full_name
          xml.email u.email
        }
      end
    }
    xml.projects {
      @projects.each do |p|
        xml.name p.name, id: p.id
      end
    }
    xml.columns {
      @datacolumns.each do |dc|
        xml.column {
          xml.header dc.columnheader
          xml.definition dc.definition
          xml.unit dc.unit
          xml.type dc.import_data_type
          xml.instrumentation dc.instrumentation
          xml.reference dc.informationsource
          xml.datagroup(id: dc.datagroup_id) {
            xml.title dc.datagroup.title
            xml.description dc.datagroup.description
          }
        }
        if params[:separate_category_columns].to_s.downcase.eql?("true")  && dc.split_me?
          xml.column {
            xml.header dc.columnheader + "_Categories"
            xml.definition dc.definition
            xml.unit dc.unit
            xml.type "category"
            xml.instrumentation dc.instrumentation
            xml.reference dc.informationsource
            xml.datagroup(id: dc.datagroup_id) {
              xml.title dc.datagroup.title
              xml.description dc.datagroup.description
            }
          }
        end
      end
    }
    xml.urls {
      xml.xls download_dataset_url(@dataset, user_credentials: current_user.try(:single_access_token))
      xml.csv download_dataset_url(@dataset, format: :csv, separate_category_columns: true, user_credentials: current_user.try(:single_access_token))
    }
    xml.keywords {
      @tags.each do |t|
        xml.keyword t.name, id: t.id
      end
    }
    xml.attachments {
      @freeformats.each do |f|
        xml.attachment(id: f.id) {
          xml.fileName f.file_file_name
          xml.description f.description
          xml.fileType f.file_content_type
          xml.url download_freeformat_url(f, user_credentials: current_user.try(:single_access_token))
        }
      end
    }
  else
    xml.error "The meta data is not visibile for unlogged-in users"
  end
}
