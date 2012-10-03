Befchina::Application.routes.draw do

  root :to => "pages#home"

  resource :user_session
  match 'login' => 'user_sessions#new', :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout

  resources :users
  match 'profile' => 'users#edit', :as => :profile

  match 'imprint' => 'pages#imprint', :as => :imprint
  match 'help' => 'pages#help', :as => :help
  match 'data' => 'pages#data', :as => :data

  resources :datasets do
    member do
      post :delete_imported_research_data_and_file, :approve_predefined, :batch_update_columns
      get :download, :edit_files, :importing, :regenerate_download, :approve, :approval_quick
    end
  end

  match 'download_excel_template' => 'datasets#download_excel_template'

  match 'files/freeformats/:id/download' => 'freeformats#download'
  match 'files/freeformats/:id/destroy' => 'freeformats#destroy'
  match 'files/freeformats/create' => 'freeformats#create'
  match 'files/freeformats/:id/update' => 'freeformats#update'

  resources :keywords, :controller => 'tags'

  resources :projects

  resources :datacolumns do
    member do
      get :approval_overview, :next_approval_step,
          :approve_datagroup, :approve_datatype, :approve_metadata, :approve_invalid_values
      post :update_datagroup, :create_and_update_datagroup, :update_datatype, :update_metadata, :update_invalid_values
    end
  end

  resources :paperproposals
  match 'paperproposals/update_vote/:id' => 'paperproposals#update_vote', :as => :update_vote
  match 'paperproposals/update_state/:id' => 'paperproposals#update_state', :as => :paperproposal_update_state

  namespace :admin do
    resources :datasets, :projects, :users, :datagroups, :tags,
              :datacolumns, :categories, :freeformats, :paperproposals do
      as_routes
    end
  end

  namespace :settings do
    resources :users, :datasets, :datacolumns do
      as_routes
    end
  end

  resources :carts
  match 'create_cart_context/:dataset_id' => 'carts#create_cart_context', :as => :create_cart_context
  match 'delete_cart_context/:dataset_id' => 'carts#delete_cart_context', :as => :delete_cart_context
  match 'cart' => 'carts#show', :as => 'current_cart'

  resources :datagroups do
    member do
      get :upload_categories
      post :update_categories
    end
  end

  resources :categories do
    member do
      get :upload_sheetcells
      post :update_sheetcells
    end
  end

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
