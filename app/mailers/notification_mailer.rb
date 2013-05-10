class NotificationMailer < ActionMailer::Base
  #default from: "from@example.com" # TODO: read from config file!

  def data_request_rejected(paperproposal)
    @paperproposal = paperproposal
    user = @paperproposal.author
    subject = 'Data request rejected'
    message = render_to_string 'data_request_rejected'

    create_notification(user, subject, message)
  end

  def auto_accept_for_free_datasets(user, paperproposal)
    @user = user
    @paperproposal = paperproposal
    subject = 'Free dataset(s) used in paperproposal'
    message = render_to_string 'auto_accept_for_free_datasets'

    create_notification(user, subject, message)
  end

private

  def create_notification(user, subject, message)
    user.notifications.create(:subject => subject, :message => message)
  end

end
