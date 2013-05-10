class NotificationMailer < ActionMailer::Base
  #default from: "from@example.com" # TODO: read from config file!

  def data_request_rejected(paperproposal)
    @paperproposal = paperproposal
    user = @paperproposal.author
    subject = 'Data request rejected'
    message = render_to_string 'data_request_rejected'

    user.notifications.create(:subject => subject, :message => message)
  end


end
