module FreeformatsHelper

  def complete_freeformat_url (freeformat, with_user_credentials = false)
    url = "#{request.protocol}#{request.host_with_port}#{freeformat.file.url}"
    if with_user_credentials
      url += "&user_credentials=#{current_user.try(:single_access_token)}"
    end
    url
  end

end