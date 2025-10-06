defmodule Remembly.Remember do
  use Ash.Domain, extensions: [AshJsonApi.Domain, AshGraphql.Domain, AshPhoenix]

  graphql do
    queries do
      get Remembly.Remember.Memory, :website_memory_get, :read
      list Remembly.Remember.Memory, :website_memory_list, :read
    end

    mutations do
      create Remembly.Remember.Memory, :website_memory_create, :create_website_memory
    end
  end

  json_api do
    routes do
      # in the domain `base_route` acts like a scope
      base_route "/memories", Remembly.Remember.Memory do
        get :read
        index :read
        post :create
      end

      base_route "/categories", Remembly.Remember.Category do
        get :read
        index :read
        post :create
      end
    end
  end

  resources do
    resource Remembly.Remember.Category do
      define :category, action: :remember_category
    end

    resource Remembly.Remember.Memory do
      define :create_website_memory
      define :create_manual_memory
      define :create_message_memory
      define :remember_message_memories
      define :remember_memories
    end

    resource Remembly.Remember.Message

    resource Remembly.Remember.OgData do
      define :create_og_data
    end

    resource Remembly.Remember.Website
  end
end
