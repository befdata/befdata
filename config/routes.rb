Befchina::Application.routes.draw do

  root :to => "pages#home"

  resource :user_session, :only => [:create]
  match 'login' => 'user_sessions#new', :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout

  resources :users
  resource :profile, :only => [:show, :edit, :update] do
    member do
      get :votes, :votes_history, :update_credentials
      resources :notifications, :only => [:index, :destroy] do
        get :mark_as_read, :on => :member
      end
    end
  end

  match 'imprint' => 'pages#imprint', :as => :imprint
  match 'help' => 'pages#help', :as => :help
  match 'data' => 'pages#data', :as => :data
  match 'search' => 'pages#search'

  resources :datasets do
    resources :datafiles, :only => [:destroy] do
      get :download, :on => :member
    end
    resources :dataset_edits, :only => [:index] do
      post :submit, :on => :member
    end
    member do
      post :update_workbook, :approve_predefined, :batch_update_columns
      get :download, :edit_files, :importing, :regenerate_download, :approve, :approval_quick,
          :keywords, :download_page, :download_status, :freeformats_csv
    end
  end

  match 'download_excel_template' => 'datasets#download_excel_template'

  scope :path => "/files" do
    resources :freeformats, :only => [:create, :update, :destroy] do
      get :download, :on => :member
    end
  end

  resources :keywords, :controller => 'tags'

  resources :projects

  resources :datacolumns do
    member do
      get :approval_overview, :next_approval_step,
          :approve_datagroup, :approve_datatype, :approve_metadata, :approve_invalid_values
      post :update_datagroup, :create_and_update_datagroup, :update_datatype, :update_metadata, :update_invalid_values,
           :update_invalid_values_with_csv, :autofill_and_update_invalid_values
    end
  end

  resources :paperproposals do
    member do
      get :edit_datasets, :edit_files, :safe_delete,
          :administrate_votes, :admin_approve_all_votes, :admin_reset_all_votes, :admin_hard_reset
      post :update_datasets
    end
  end
  match 'paperproposals/update_vote/:id' => 'paperproposals#update_vote', :as => :update_vote
  match 'paperproposals/update_state/:id' => 'paperproposals#update_state', :as => :paperproposal_update_state

  resources :carts
  match 'create_cart_context/:dataset_id' => 'carts#create_cart_context', :as => :create_cart_context
  match 'delete_cart_context/:dataset_id' => 'carts#delete_cart_context', :as => :delete_cart_context
  match 'cart' => 'carts#show', :as => 'current_cart'

  resources :datagroups do
    member do
      get :upload_categories, :datacolumns
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
