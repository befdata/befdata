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
    validate_sort_params(collection: ['title', 'last_update', 'id'], default: 'title')
    @tags = DatasetTag.tag_counts

    @datasets = Dataset.scoped
    @filter_params = BefParam.new(params[:q], :checkbox => :access_code, :radio => :f)

    @datasets = @datasets.where(access_code: @filter_params[:access_code]) if @filter_params.has_param? :access_code

    @datasets = @datasets.where(['datafiles_count > 0']) if @filter_params.has_param?(:f, 'w')
    @datasets = @datasets.where(['freeformats_count > 0']) if @filter_params.has_param?(:f, 'a')
    @datasets = @datasets.where(['freeformats_count = 0 and datafiles_count = 0']) if @filter_params.has_param?(:f, 'n')
    @datasets = @datasets.where(['datafiles_count > 0 or freeformats_count > 0']) if @filter_params.has_param?(:f, %w{a w})

    @datasets = @datasets.select("id, title, updated_at as last_update")
                         .order("#{params[:sort]} #{params[:direction]}")
                         .paginate(page: params[:page], per_page: 50)
  end

  def search
    if params[:q].blank?
      flash.now[:error] = "You should specify a search term."
    else
      @datasets = Dataset.search(params[:q]) | Datacolumn.includes(:dataset).search(params[:q]).uniq_by(&:dataset_id).map(&:dataset)
    end
  end
end
