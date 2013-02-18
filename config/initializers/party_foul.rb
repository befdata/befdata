PartyFoul.configure do |config|
  # The collection of exceptions PartyFoul should not be allowed to handle
  # The constants here *must* be represented as strings
  config.blacklisted_exceptions = ['ActiveRecord::RecordNotFound', 'ActionController::RoutingError']

  # The OAuth token for the account that is opening the issues on GitHub
  config.oauth_token            = CONFIG[:party_foul_github_oauth_token]

  # The API endpoint for GitHub. Unless you are hosting a private
  # instance of Enterprise GitHub you do not need to include this
  config.endpoint               = 'https://api.github.com'

  # The Web URL for GitHub. Unless you are hosting a private
  # instance of Enterprise GitHub you do not need to include this
  config.web_url                = 'https://github.com'

  # The organization or user that owns the target repository
  config.owner                  = CONFIG[:party_foul_github_username]

  # The repository for this application
  config.repo                   = CONFIG[:party_foul_github_repository]

  # The branch for your deployed code
  config.branch               = 'master'

  # Additional labels to add to issues created
  # config.additional_labels    = ['production']
  # or
  # config.additional_labels    = Proc.new do |exception, env|
  #   []
  # end

  # Limit the number of comments per issue
  # config.comment_limit        = 10
end
