class NotificationMailer < ActionMailer::Base

  default :from => self.smtp_settings[:default_from]

  def data_request_rejected(paperproposal)
    set_host #before action and filter only will work in rails 4

    @paperproposal = paperproposal
    user = @paperproposal.author
    subject = 'Data request rejected'
    message = render_to_string 'data_request_rejected'

    create_notification(user, subject, message)
    send_mail(user, subject)
  end

  def auto_accept_for_free_datasets(user, paperproposal)
    set_host #before action and filter only will work in rails 4

    @user = user
    @paperproposal = paperproposal
    subject = 'Free dataset(s) used in paperproposal'
    message = render_to_string 'auto_accept_for_free_datasets'

    create_notification(user, subject, message)
    send_mail(user, subject)
  end

  def dataset_edit(user, dataset_edit, user_function)
    set_host #before action and filter only will work in rails 4

    @user = user
    @dataset_edit = dataset_edit
    @user_function = user_function

    subject = 'Dataset was edited'
    message = render_to_string 'dataset_edit'

    create_notification(user, subject, message)
    send_mail(user, subject)
  end

private

  def create_notification(user, subject, message)
    user.notifications.create(:subject => subject, :message => message)
  end

  def send_mail(user, subject)
    recipient = Rails.env == 'development' ? self.smtp_settings[:default_from] : user.email # dev mode sends maisl to notification address

    mail(:to => recipient, :subject => subject) do |format|
      format.html {render :layout => 'notification_mail'}
    end
  end

  def set_host
    @host = self.smtp_settings[:application_host]
  end

end
