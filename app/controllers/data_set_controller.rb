class DataSetController < ApplicationController




  def upload
    if !params[:filevalue_id].blank?
      # When coming from the upload page, a file parameter must be
      # set.  This means, that there has not been any context yet
      # made with this file.

      filevalue = Filevalue.find(params[:filevalue_id])
      begin

        filepath = filevalue.file.path
        book = Spreadsheet.open filepath
        # after closing, the file can be destroyed if necessary, the
        # information stays in the book object
        book.io.close

        # Start with the first sheet; if the page is reloaded, there
        # may already be a context to this filevalue
        if filevalue.context.blank?
          @context = Context.new
          @context.upload_spreadsheet = filevalue

          # gather all the cell values that can just be copied into
          # the new context
          filename = filevalue.file_file_name
          simple_hash = gather_simple_general_metadata(filename, book)
          @context.update_attributes(simple_hash)


          def parse_date_txt(date_text, day_month_txt)
            begin
              if integer?(date_text)
                date_text = date_text.to_i.to_s
                date_text = day_month_txt + date_text if date_text.length == 4
              end
              date_tmp = DateTime.parse(date_text)
            rescue ArgumentError
              date_tmp = DateTime.parse(Date.today.to_s)
            end
            return(date_tmp)
          end

          logger.debug "-- data conversion --"
          datemin = Array(book.worksheet(0).column(0))[32].to_s
          logger.debug "-- datemin #{datemin} --"
          day_month = "1/1/"
          @context.datemin = parse_date_txt(datemin, day_month)
          datemax = Array(book.worksheet(0).column(0))[34].to_s
          logger.debug "-- datemax #{datemax} --"
          day_month = "12/31/"
          @context.datemax = parse_date_txt(datemax, day_month)



          @context.save
          logger.debug "---------- after saving the new context -------"
          logger.debug @context.valid?
          logger.debug @context.errors.inspect


          # Gather the people
          # Determine number of people
          cols = Array(book.worksheet(0).row(14)).length
          ppl = cols - 1 # The first column contains only meta data
          logger.debug "------------ ppl.inspect  ---------"
          logger.debug ppl.inspect

#          # The current user is automatically added to the user array
#          logger.debug "---------- after saving the new context -------"
#          people = [@current_user]
          people = []

          ppl.times do |i| # starts at 0
            person = Array(book.worksheet(0).column(i+1))[14..15]
            logger.debug "------------ person.inspect  ---------"
            logger.debug person.inspect
            # Look for the givenName in both name fields
            people += Person.find_all_by_firstname(person[0])
            # people += Person.find_all_by_lastname(person[0])

            # Look for the surName in both name fields
            # people += Person.find_all_by_firstname(person[1])
            people += Person.find_all_by_lastname(person[1])

            # Additionally, do a fuzzy search on both name values
            # people += Person.fuzzy_find(person[0]) # givenName
            # people += Person.fuzzy_find(person[1]) # surName

            people = people.uniq # Eliminate the doubled entries
          end


          # Add all found roles to the context. Evaluation of
          # correctness will be step 2
          people.each do |pr|
            pr.has_role! :owner, @context
          end

        else # there already is context information for this file
          @context = filevalue.context
        end

        # Project Tag list
        proj_tag_list = Array(book.worksheet(0).column(1))[11]
        @context.projecttag_list = proj_tag_list
        @context.save

        # Render the page that presents the general metadata for a
        # data set, for user interaction
        # (view/contexts/upload.html.erb)
        @step = 1
        @people_list = Person.find(:all, :order => :lastname)
      rescue Ole::Storage::FormatError
        # Uploaded file was no valid Excel file
        redirect_to data_path and return
      end

    elsif params[:step] == '1'
      # At this point, the parameter "filename" is given; there has
      # already an upload been done, the context for which "upload"
      # is called is already existing.  Because of this, the upload
      # of a file is leaped over.  We are at step 1.
      @context = Context.find(params[:id])
      unless @context.blank?

        people = Person.find(params[:people])

        # assigning provenance information: linking people to the data
        # set
        people.each do |pr|
          pr.has_role! :owner, @context
        end

        @context.update_attributes( :title => params[:title],
                                    :abstract => params[:abstract],
                                    :comment => params[:comment],
                                    :usagerights => params[:usagerights],
                                    :published => params[:published],
                                    :spatialextent => params[:spatialextent],
          :datemin => DateTime.civil(params[:date][:"min(1i)"].to_i, params[:date][:"min(2i)"].to_i, params[:date][:"min(3i)"].to_i, params[:date][:"min(4i)"].to_i, params[:date][:"min(5i)"].to_i),
          :datemax => DateTime.civil(params[:date][:"max(1i)"].to_i, params[:date][:"max(2i)"].to_i, params[:date][:"max(3i)"].to_i, params[:date][:"max(4i)"].to_i, params[:date][:"max(5i)"].to_i),
                                    :temporalextent => params[:temporalextent],
                                    :taxonomicextent => params[:taxonomicextent],
                                    :design => params[:design],
                                    :dataanalysis => params[:dataanalysis],
                                    :circumstances => params[:circumstances] )

        # Finally, set the new step, so that the evaluation process
        # moves forward
        redirect_to url_for(:controller => :import,
                            :action => :raw_data_overview,
                            :context_id => @context.id) and return

      else
        # No context found
        redirect_to data_path and return
      end
    elsif params[:step] == '5'
      @step = 5
      logger.debug " entering step 5 "

      @context = Context.find(params[:context_id])
      logger.debug " loading context "
      logger.debug @context.inspect

      unless @context.blank?
        # Upoading and evaluation finished
        logger.debug "Upoading and evaluation finished, showing params[:finished]"
        logger.info params[:finished]
        @context.finished = params[:finished]
        @context.save


        # If the context is finished, show it
        if @context.finished == true
          logger.debug "After all, rebuild the search index"
          # After all, rebuild the search index
          begin
            Context.rebuild_index
            logger.debug "rebuilding done"
          rescue
            logger.debug "rebuilding did not work"
          end

          redirect_to url_for :controller => :contexts,
                              :action => :show,
                              :id => @context.id and return
        else
          logger.debug "context not finished"
          logger.debug [@context.id, @context.title].to_s
        end
      else
        # No context found
        redirect_to data_path and return
      end
    else
      # Neither file parameter nor step parameter. Redirect to the
      # upload page.
      redirect_to data_path and return
    end
#    else
#      # Not logged in, redirect to login form
#      session[:return_to] = request.request_uri
#      redirect_to login_path and return
#    end
  end



end
