# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Remembly.Repo.insert!(%Remembly.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
default_category = Remembly.Remember.category!(%{label: "Default"})
funny = Remembly.Remember.category!(%{label: "Funny"})
home_lab = Remembly.Remember.category!(%{label: "HomeLab"})
instruments = Remembly.Remember.category!(%{label: "Instruments"})
programming = Remembly.Remember.category!(%{label: "Programming"})

Remembly.Remember.create_website_memory!(%{
  content:
    "Elixir is a dynamic, functional language designed for building scalable and maintainable applications.",
  description: "Learning about Elixir",
  category_id: default_category.id,
  website_params: %{
    url: "https://elixir-lang.org/"
  }
})

Remembly.Remember.create_website_memory!(%{
  content: "Phoenix is a web development framework written in Elixir.",
  description: "Learning about Phoenix",
  category_id: programming.id,
  website_params: %{
    url: "https://www.phoenixframework.org/"
  }
})

Remembly.Remember.create_website_memory!(%{
  content: "Ash is a powerful framework for building data layers in Elixir.",
  description: "Learning about Ash",
  category_id: programming.id,
  website_params: %{
    url: "https://ash-hq.org/"
  }
})

Remembly.Remember.create_website_memory!(%{
  content: "https://www.sweetwater.com/?msockid=0f1516ee1b266e181b1302b41ab46f13",
  description: "Sweetwater - Music Instruments and Pro Audio",
  category_id: instruments.id,
  website_params: %{
    url: "https://www.sweetwater.com/"
  }
})

Remembly.Remember.create_message_memory!(%{
  content: "https://uk.pinterest.com/pin/350366046008794799/",
  description: "A meme I saw",
  source: "discord",
  category_id: funny.id,
  message_params: %{
    reference_id: "1"
  }
})

Remembly.Remember.create_message_memory!(%{
  content: "https://uk.pinterest.com/pin/23573598047040578/",
  description: "A meme I saw",
  source: "discord",
  category_id: funny.id,
  message_params: %{
    reference_id: "2"
  }
})

Remembly.Remember.create_message_memory!(%{
  content: "https://www.youtube.com/watch?v=Q3bY0qHl8gw",
  description: "YouTube video I saw",
  source: "discord",
  category_id: home_lab.id,
  message_params: %{
    reference_id: "3"
  }
})

Remembly.Remember.create_message_memory!(%{
  content: "https://www.youtube.com/watch?v=4RWw2KsIK0Y",
  description: "YouTube video I saw",
  source: "discord",
  category_id: home_lab.id,
  message_params: %{
    reference_id: "4"
  }
})
