defmodule Remembly.Remember.Message do
  use Ash.Resource,
    otp_app: :remembly,
    domain: Remembly.Remember,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshJsonApi.Resource]

  require Ash.Expr

  json_api do
    type "message"
  end

  postgres do
    table "messages"
    repo Remembly.Repo
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]

    create :remember_message do
      accept [:reference_id, :content]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :content, :string, allow_nil?: false, public?: true
    attribute :reference_id, :string, allow_nil?: false

    timestamps(public?: true)
  end

  relationships do
    belongs_to :category, Remembly.Remember.Category, public?: true
  end

  calculations do
    calculate :short_content, :string, Remembly.Remember.Message.Calculations.ShortContent,
      allow_nil?: false
  end

  identities do
    identity :message_reference_id, [:reference_id]
  end
end
