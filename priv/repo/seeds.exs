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
Remembly.Remember.message!(%{content: "This is a cool [link]"})
Remembly.Remember.message!(%{content: "Article about crazy stuff [link]"})
Remembly.Remember.message!(%{content: "YouTube video [link]"})
Remembly.Remember.message!(%{content: "Some tutorial I need the next time I'm doing xyz [link]"})
Remembly.Remember.message!(%{content: "My kid's birthday video [link]"})
Remembly.Remember.message!(%{content: "Storm footage [link]"})
