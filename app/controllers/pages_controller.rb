class PagesController < ApplicationController

  skip_before_filter :deny_access_to_all
  access_control do
    actions :home, :imprint, :help, :data do
      allow all
    end
  end

  def home
  end

  def imprint
    @external_usages = [
      ['Rails','http://rubyonrails.org/'],
      ['Rake','http://rake.rubyforge.org/'],
      ['Pg','https://bitbucket.org/ged/ruby-pg'],
      ['Haml','http://haml-lang.com/'],
      ['Authlogic','https://github.com/binarylogic/authlogic'],
      ['Acl9','https://github.com/be9/acl9'],
      ['Dynamic_form','https://github.com/rails/dynamic_form'],
      ['Paperclip','https://github.com/thoughtbot/paperclip'],
      ['Acts-as-taggable-on','https://github.com/mbleigh/acts-as-taggable-on'],
      ['Spreadsheet','http://spreadsheet.rubyforge.org/'],
      ['Yaml_db','https://github.com/ludicast/yaml_db'],
      ['Active_scaffold','https://github.com/activescaffold/active_scaffold/blob/master/MIT-LICENSE'],
      ['Delayed_job','https://github.com/collectiveidea/delayed_job'],
      ['Activerecord-import','https://github.com/zdennis/activerecord-import'],
      ['Test-unit','http://test-unit.rubyforge.org/'],
      ['Ruby-prof','http://ruby-prof.rubyforge.org/'],
      ['PostgreSQL','http://www.postgresql.org/'],
      ['JQuery','http://jquery.org/'],
      ['JQuery Tablesorter','http://tablesorter.com/'],
      ['JQuery UI','http://jqueryui.com/'],
      ['Blueprint CSS','http://blueprintcss.org/'],
    ]
  end

  def help
  end

  # This method is the dashboard method of our Portal
  # This provide a first look to our metadata and give a hint about our data
  def data
    @tags = ActsAsTaggableOn::Tag.order(:name)
    @datasets = Dataset.order(:title)
  end

end
