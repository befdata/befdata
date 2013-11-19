class PagesController < ApplicationController

  skip_before_filter :deny_access_to_all
  access_control do
    actions :home, :imprint, :help, :data, :search do
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
      ['Delayed_job','https://github.com/collectiveidea/delayed_job'],
      ['Daemons','http://daemons.rubyforge.org/'],
      ['Whenever','https://github.com/javan/whenever/'],
      ['Test-unit','http://test-unit.rubyforge.org/'],
      ['Ruby-prof','http://ruby-prof.rubyforge.org/'],
      ['PostgreSQL','http://www.postgresql.org/'],
      ['JQuery','http://jquery.org/'],
      ['JQuery Tablesorter','http://tablesorter.com/'],
      ['JQuery UI','http://jqueryui.com/'],
      ['SimpleModal','http://www.ericmmartin.com/projects/simplemodal/'],
      ['Blueprint CSS','http://blueprintcss.org/'],
      ['Pg_Search', 'https://github.com/Casecommons/pg_search'],
      ['select2', 'http://ivaynberg.github.com/select2']
    ]
  end

  # This method is the dashboard method of our Portal
  # This provide a first look to our metadata and give a hint about our data
  def data
    validate_sort_params
    @tags = DatasetTag.tag_counts
    @datasets = Dataset.joins_datafile_and_freeformats(params[:workbook]).select("datasets.id, title, 
      GREATEST(datasets.updated_at, max(freeformats.updated_at)) as last_update,
      count(datafiles.id)").order("#{params[:sort]} #{params[:direction]}")
  end

  def search
    if params[:q].blank?
      flash.now[:error] = "You should specify a search term."
    else
      @datasets = Dataset.search(params[:q]) | Datacolumn.includes(:dataset).search(params[:q]).uniq_by(&:dataset_id).map(&:dataset)
    end
  end

private
  def validate_sort_params
    params[:sort] = 'title' unless ['title', 'id', 'last_update'].include?(params[:sort])
    params[:direction] = 'asc' unless ["desc", "asc"].include?(params[:direction])
  end

end
