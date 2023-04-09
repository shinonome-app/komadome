# frozen_string_literal: true

## CONSONANTS = ["a", "ka", "sa", "ta", "na", "ha", "ma", "ya", "ra", "wa", "zz"]

Rails.application.routes.draw do
  get '/index', to: 'top#index'

  root to: 'top#index'

  # health check
  get 'up' => 'health#show'

  # kick task
  post 'kick' => 'kick#create'

  resources :index_pages, only: [] do
    collection do
      get 'index_top'
      get 'index_all'

      ## People
      get 'person_:id', to: 'people#index', constraints: { id: /[kstnhmyrw]?a|zz/ }, as: :people
      get 'person:id', to: 'people#show', constraints: { id: /\d+/ }, as: :person

      get 'person_all_:id', to: 'index_pages#person_all_index', constraints: { id: /[kstnhmyrw]?a|zz/ }

      get 'person_inp_:id', to: 'index_pages#person_inp_index', constraints: { id: /[kstnhmyrw]?a|zz/ }

      get 'person_all', to: 'index_pages#person_all'

      get 'list_inp:id_page', to: 'index_pages#list_inp_show', constraints: { id_page: /\d+_\d+/ }, as: :list_inp

      get 'sakuhin_:id_page', to: 'index_pages#work_index', constraints: { id_page: /([kstnhmyrw]?[aiueo]|zz|nn)\d+/ }, as: :sakuhin

      get 'sakuhin_inp_:id_page', to: 'index_pages#work_inp_index', constraints: { id_page: /([kstnhmyrw]?[aiueo]|zz|nn)\d+/ }, as: :sakuhin_inp

      # Whatsnew
      get 'whatsnew:page', to: 'whatsnews#index', constraints: { page: /\d+/ }, as: :whatsnew
      get 'whatsnew_:year_page', to: 'whatsnews#index_year', constraints: { year_page: /\d\d\d\d_\d+/ }, as: :whatsnew_year

      # Download zip files
      get 'list_person_all', to: 'downloads#list_person_all', constraints: { format: 'zip' }
      get 'list_person_all_extended', to: 'downloads#list_person_all_extended', constraints: { format: 'zip' }
      get 'list_person_all_utf8', to: 'downloads#list_person_all_utf8', constraints: { format: 'zip' }
      get 'list_person_all_extended_utf8', to: 'downloads#list_person_all_extended_utf8', constraints: { format: 'zip' }
    end
  end

  scope '/soramoyou' do
    get 'soramoyouindex', to: 'news_entries#index', as: :soramoyou_index
    get 'soramoyou:year', to: 'news_entries#index_year', constraints: { year: /\d\d\d\d/ }, as: :soramoyou_year
  end

  get 'cards/:person_id/card:card_id', to: 'cards#show', constraints: { person_id: /\d+/, card_id: /\d+/ }, as: :card
end
