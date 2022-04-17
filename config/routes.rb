
## CONSONANTS = ["a", "ka", "sa", "ta", "na", "ha", "ma", "ya", "ra", "wa", "zz"]

Rails.application.routes.draw do
  get '/index', to: 'top#index'

  root to: 'top#index'


  resources :index_pages, only: [] do
    collection do
      get 'index_top'
      get 'index_all'

      get 'whatsnew:page', to: 'whatsnews#index', constraints: { page: /\d+/ }

      get 'whatsnew_:year_page', to: 'whatsnews#index_year', constraints: { year_page: /\d\d\d\d_\d+/ }

      get 'person_:id', to: 'index_pages#person_index', constraints: { id: /[kstnhmyrw]?a|zz/ }
      get 'person_all_:id', to: 'index_pages#person_all_index', constraints: { id: /[kstnhmyrw]?a|zz/ }

      get 'person_inp_:id', to: 'index_pages#person_inp_index', constraints: { id: /[kstnhmyrw]?a|zz/ }

      get 'person_all', to: 'index_pages#person_all'

      get 'person:id', to: 'index_pages#person_show', constraints: { id: /\d+/ }

      get 'list_inp:id_page', to: 'index_pages#list_inp_show', constraints: { id_page: /\d+_\d+/ }

      get 'sakuhin_:id_page', to: 'index_pages#work_index', constraints: { id_page: /([kstnhmyrw]?[aiueo]|zz)\d+/ }, as: :sakuhin

      get 'sakuhin_inp_:id_page', to: 'index_pages#work_inp_index', constraints: { id_page: /([kstnhmyrw]?[aiueo]|zz)\d+/ }, as: :sakuhin_inp


      # Download zip files
      get 'list_person_all', to: 'downloads#list_person_all', constraints: {format: 'zip'}
      get 'list_person_all_extended', to: 'downloads#list_person_all_extended', constraints: {format: 'zip'}
      get 'list_person_all_utf8', to: 'downloads#list_person_all_utf8', constraints: {format: 'zip'}
      get 'list_person_all_extended_utf8', to: 'downloads#list_person_all_extended_utf8', constraints: {format: 'zip'}
    end
  end

  get 'cards/:person_id/card:card_id', to: 'cards#show', constraints: { person_id: /\d+/, card_id: /\d+/ }
end
