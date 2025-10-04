defmodule Remembly.Remember.Memory do
  use Ash.Resource,
    otp_app: :remembly,
    domain: Remembly.Remember,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshGraphql.Resource, AshJsonApi.Resource]

  require Ash.Expr

  graphql do
    type :memory
  end

  json_api do
    type "memory"
  end

  postgres do
    table "memories"
    repo Remembly.Repo

    references do
      reference :category, on_delete: :delete
    end
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    create :create_memory do
      accept [:description]
    end

    create :create_website_memory do
      accept [:content, :description]

      argument :website_params, :map, allow_nil?: false
      argument :category_id, :uuid, allow_nil?: true

      change manage_relationship(:website_params, :website, type: :create)
      change manage_relationship(:category_id, :category, type: :append_and_remove)
      change set_attribute(:source, "website")
    end

    create :create_message_memory do
      accept [:content, :description, :source]

      argument :source, :string, allow_nil?: false
      argument :message_params, :map, allow_nil?: false
      argument :category_id, :uuid, allow_nil?: true

      change manage_relationship(:message_params, :message, type: :create)
      change manage_relationship(:category_id, :category, type: :append_and_remove)
      change set_attribute(:source, arg(:source))
    end

    update :categorize_memory do
      argument :category_id, :uuid, allow_nil?: true
      require_atomic? false

      change manage_relationship(:category_id, :category, type: :append_and_remove)
    end

    read :remember_memories do
    end

    read :remember_website_memories do
      filter expr(is_nil(website_id) == false)
    end

    read :remember_message_memory do
      argument :message_id, :uuid, allow_nil?: false

      filter expr(message.id == ^arg(:message_id))
    end

    read :remember_message_memories do
      filter expr(is_nil(message.id) == false)
    end

    read :remember_memory_by_term do
      argument :term, :string, allow_nil?: false

      prepare Remembly.Remember.Memory.Preparations.Find
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :source, :string do
      allow_nil? false
      constraints max_length: 50
      default "manual"
      public? true
    end

    attribute :content, :string, allow_nil?: false, public?: true
    attribute :description, :string, public?: true

    timestamps(public?: true)
  end

  relationships do
    belongs_to :category, Remembly.Remember.Category, public?: true
    has_one :website, Remembly.Remember.Website, public?: true
    has_one :message, Remembly.Remember.Message, public?: true
  end
end
