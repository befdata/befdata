Befchina::Application.routes.draw do

  resource :user_session
  match 'login' => 'user_sessions#new', :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout

  resources :users
  match 'profile' => 'users#edit', :as => :profile

  root :to => "pages#home"
  match 'impressum' => 'pages#impressum', :as => :impressum
  match 'help' => 'pages#help', :as => :help
  match 'data' => 'pages#data', :as => :data
  match 'data/show_tags' => 'tags#index'

  resources :datasets
  match 'upload' => 'datasets#upload', :as => :upload
  match 'upload_freeformat' => 'datasets#upload_freeformat', :as => :upload_freeformat
  match 'upload_dataset_freeformat' => 'datasets#upload_dataset_freeformat', :as => :upload_dataset_freeformat
  match 'create_freeformat' => 'datasets#create_freeformat', :as => :create_freeformat
  match 'create_dataset_freeformat' => 'datasets#create_dataset_freeformat', :as => :create_dataset_freeformat
  match 'update_freeformat_associations' => 'datasets#update_freeformat_associations', :as => :update_freeformat_associations
  match 'update_dataset_freeformat_associations' => 'datasets#update_dataset_freeformat_associations', :as => :update_dataset_freeformat_associations
  match 'save_freeformat_associations' => 'datasets#save_freeformat_associations', :as => :save_freeformat_associations
  match 'save_dataset_freeformat_associations' => 'datasets#save_dataset_freeformat_associations', :as => :save_dataset_freeformat_associations
  match 'download' => 'datasets#download', :as => :download

  resources :tags
  #match 'tags/index' => 'tags#index'

  resources :projects

  match 'imports/create_dataset_filevalue' => 'imports#create_dataset_filevalue'
  match 'imports/create_freeformat_filevalue' => 'imports#create_freeformat_filevalue'
  match 'imports/create_dataset_freeformat' => 'imports#create_dataset_freeformat'
  match 'imports/raw_data_overview' => 'imports#raw_data_overview'
  match 'imports/raw_data_per_header' => 'imports#raw_data_per_header'
  match 'imports/update_data_header' => 'imports#update_data_header'
  match 'imports/update_data_group' => 'imports#update_data_group'
  match 'imports/update_people_for_data_header' => 'imports#update_people_for_data_header'
  match 'imports/add_data_values' => 'imports#add_data_values'
  match 'imports/data_column_categories' => 'imports#data_column_categories'
  match 'imports/context_export_destroy' => 'imports#context_export_destroy'
  match 'imports/cell_category_update' => 'imports#cell_category_update'
  match 'imports/cell_category_create' => 'imports#cell_category_create'
  match 'imports/freeformat_overview' => 'imports#freeformat_overview'
  match 'imports/dataset_freeformat_overview' => 'imports#dataset_freeformat_overview'
  match 'imports/save_freeformat_tags' => 'imports#save_freeformat_tags'
  match 'imports/save_dataset_freeformat_tags' => 'imports#save_dataset_freeformat_tags'

  namespace :admin do |admin|
    resources :datasets, :projects, :users, :datagroups, :tags, :datacolumns, :categoricvalues do
      as_routes
    end
  end

  resources :paperproposals
  match 'paperproposals/update_vote/:id' => 'paperproposals#update_vote', :as => :update_vote
  match 'paperproposals/update_state/:id' => 'paperproposals#update_state', :as => :paperproposal_update_state


  
  match 'files/freeformats/:id/download' => 'datasets#download_freeformat'
  match 'files/:id/download' => 'filevalues#download'


  resources :carts

  match 'create_cart_context/:dataset_id' => 'carts#create_cart_context', :as => :create_cart_context
  match 'delete_cart_context/:dataset_id' => 'carts#delete_cart_context', :as => :delete_cart_context
  match 'cart' => 'carts#show', :as => 'current_cart'



  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
