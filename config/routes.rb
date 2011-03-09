ActionController::Routing::Routes.draw do |map|

  map.resources :import_categories
  map.resources :filevalues
  map.resources :context_freeprojects
  map.resources :context_freepeople
  map.resources :carts
  map.resources :projects
  #map.project '/projects', :controller => 'projects'

  map.create_cart_context 'create_cart_context/:context_id',
                              :controller => 'carts', :action => 'create_cart_context', :method => "POST"
  map.delete_cart_context 'delete_cart_context/:cart_context_id',
                              :controller => 'carts', :action => 'delete_cart_context', :method => :delete
  map.current_cart 'cart', :controller => 'carts', :action => 'show', :id => 'current'


  map.resources :data_requests do |data_request|
    data_request.update_state 'update_state', :controller => 'data_requests', :action => 'update_state'
  end

  map.update_vote '/update_vote/:id', :controller => 'data_requests', :action => 'update_vote'


  map.connect 'files/:id/download', :controller => 'filevalues', :action => 'download'


  # User Sessions
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.profile '/profile', :controller => 'persons', :action => 'edit'
  map.resource :session




  #
  # named routes
  #
  map.data '/data', :controller => 'data'
  map.search '/data/search', :controller => 'data', :action => 'search'
  map.download '/contexts/download/:id', :controller => 'contexts', :action => 'download'
  map.upload '/contexts/upload', :controller => 'contexts', :action => 'upload'
  map.import '/import', :controller => 'import'
  map.search_contexts '/import/search_contexts', :controller => 'import',
                                                 :action => 'search_contexts'
  map.raw_data_overview '/import/raw_data_overview', :controller => 'import',
                                                     :action => 'raw_data_overview'
  map.update_raw_data_overview '/import/update_raw_data_overview',
                               :controller => 'import',
                               :action => 'update_raw_data_overview'
  map.staff '/staff/:path_name', :controller => :persons, :action => :show

  map.connect '/import/:action/', :controller => 'import'
  #map.connect '/staff/:id', :controller => 'staff', :action => :show
  map.resources :persons, :as => :staff, :except => [:show]

  map.connect '/staff/project/:id', :controller => 'persons', :action => 'project'

  map.root :controller => "pages"
  
  map.namespace :admin do |admin|
    admin.root :controller => 'pages'
    admin.resource :pages
    admin.resources :people
    admin.resources :person_roles
    admin.resources :institutions
    admin.resources :projects
    admin.resources :roles
    admin.resources :methods
    admin.resources :contexts
    admin.resources :measurements_methodsteps
    admin.resources :tags
    admin.resources :categoricvalues
    admin.connect ':controller/update_table', :action => 'update_table'
    admin.connect ':controller/browse', :action => 'browse'
    admin.connect ':controller/new', :action => 'new'
    admin.connect ':controller/create', :action => 'create'
    admin.connect ':controller/show_search', :action => 'show_search'
  end

  #ToDo This Routes have to been removed. But after that nothing work anymore.
  map.connect ':action', :controller => 'pages'
  map.connect ':controller/:action/:id'
end
