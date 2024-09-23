defmodule Remembly.Commands do
  def all_commands_list do
    test_command = %{
      name: "test",
      description: "Basic command",
      type: 1,
      integration_types: [0, 1],
      contexts: [0, 1, 2]
    }

    remember_command = %{
      name: "remember",
      type: 3,
      integration_types: [0, 1],
      contexts: [0, 1, 2]
    }

    recall_command = %{
      name: "recall",
      description: "Recall all saved messages",
      type: 1,
      integration_types: [0, 1],
      contexts: [0, 1, 2]
    }

    [test_command, remember_command, recall_command]
  end
end
