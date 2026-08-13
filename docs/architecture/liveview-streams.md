---
type: architecture
title: LiveView Streams
description: Using LiveView streams for collections — append, reset, filter, and empty states.
tags: [liveview, streams, elixir]
timestamp: 2026-07-23T00:00:00Z
---

See also [liveview.md](liveview.md) for general LiveView module conventions and [heex-templates.md](heex-templates.md) for HEEx syntax.

- **Always** use LiveView streams for collections for assigning regular lists to avoid memory ballooning and runtime termination with the following operations:
  - basic append of N items - `stream(socket, :messages, [new_msg])`
  - resetting stream with new items - `stream(socket, :messages, [new_msg], reset: true)` (e.g. for filtering items)
  - prepend to stream - `stream(socket, :messages, [new_msg], at: -1)`
  - deleting items - `stream_delete(socket, :messages, msg)`

- When using the `stream/3` interfaces in the LiveView, the LiveView template must 1) always set `phx-update="stream"` on the parent element, with a DOM id on the parent element like `id="messages"` and 2) consume the `@streams.stream_name` collection and use the id as the DOM id for each child. For a call like `stream(socket, :messages, [new_msg])` in the LiveView, the template would be:

  ```heex
  <div id="messages" phx-update="stream">
    <div :for={{id, msg} <- @streams.messages} id={id}>
      {msg.text}
    </div>
  </div>
  ```

- LiveView streams are *not* enumerable, so you cannot use `Enum.filter/2` or `Enum.reject/2` on them. Instead, if you want to filter, prune, or refresh a list of items on the UI, you **must refetch the data and re-stream the entire stream collection, passing reset: true**:

  ```elixir
  def handle_event("filter", %{"filter" => filter}, socket) do
    # re-fetch the messages based on the filter
    messages = list_messages(filter)

    {:noreply,
     socket
     |> assign(:messages_empty?, messages == [])
     # reset the stream with the new messages
     |> stream(:messages, messages, reset: true)}
  end
  ```

- LiveView streams *do not support counting or empty states*. If you need to display a count, you must track it using a separate assign. For empty states, you can use Tailwind classes:

  ```heex
  <div id="tasks" phx-update="stream">
    <div class="hidden only:block">No tasks yet</div>
    <div :for={{id, task} <- @streams.tasks} id={id}>
      {task.name}
    </div>
  </div>
  ```

  The above only works if the empty state is the only HTML block alongside the stream for-comprehension.

- When updating an assign that should change content inside any streamed item(s), you MUST re-stream the items along with the updated assign:

  ```elixir
  def handle_event("edit_message", %{"message_id" => message_id}, socket) do
    message = Chat.get_message!(message_id)
    edit_form = to_form(Chat.change_message(message, %{content: message.content}))

    # re-insert message so @editing_message_id toggle logic takes effect for that stream item
    {:noreply,
     socket
     |> stream_insert(:messages, message)
     |> assign(:editing_message_id, String.to_integer(message_id))
     |> assign(:edit_form, edit_form)}
  end
  ```

  And in the template:

  ```heex
  <div id="messages" phx-update="stream">
    <div :for={{id, message} <- @streams.messages} id={id} class="flex group">
      {message.username}
      <%= if @editing_message_id == message.id do %>
        <%!-- Edit mode --%>
        <.form for={@edit_form} id="edit-form-#{message.id}" phx-submit="save_edit">
          ...
        </.form>
      <% end %>
    </div>
  </div>
  ```

- **Never** use the deprecated `phx-update="append"` or `phx-update="prepend"` for collections
