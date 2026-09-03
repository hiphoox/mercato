defmodule MercatoWeb.Admin.FeesLive do
  @moduledoc """
  What the marketplace takes off a seller's earnings, and what it adds to what
  a buyer pays.

  Two tables of named rows rather than two settings: a commission, a
  jurisdiction's tax stacked on that commission, and a buyer's protection fee
  are the same shape of thing, and which of them a marketplace charges is its
  own business. A fresh install charges none and the tables are empty.

  Each table has one form under it, adding a row or editing the one an operator
  picked. Amounts are typed the way a person writes money and rates the way
  they write a percentage; both are stored as integers.
  """

  use MercatoWeb, :live_view

  import MercatoWeb.UI.Breadcrumb

  alias Mercato.Accounts.Setting
  alias Mercato.Money
  alias Mercato.Payments
  alias Mercato.Payments.BuyerFee
  alias Mercato.Payments.SellerDeduction

  on_mount {MercatoWeb.LiveUserAuth, :live_admin_required}

  # The two tables differ in one thing only — a deduction may be a percentage of
  # another deduction, a fee may not — so they are described rather than
  # written twice.
  #
  # Built per render rather than held as a module attribute: wording baked in at
  # compile time is invisible to translation extraction.
  defp sections do
    [
      %{
        key: :seller,
        as: "seller_deduction",
        dom: "seller-deduction",
        title: gettext("What is deducted from a seller"),
        hint: gettext("Taken off what a seller is paid when a sale completes."),
        empty: gettext("Nothing is deducted. A seller keeps the whole sale price."),
        add: gettext("Add a deduction"),
        edit: gettext("Edit this deduction"),
        stackable?: true
      },
      %{
        key: :buyer,
        as: "buyer_fee",
        dom: "buyer-fee",
        title: gettext("What a buyer is charged on top"),
        hint: gettext("Added to the sale price at checkout, rather than taken from the seller."),
        empty: gettext("Nothing is charged. A buyer pays the sale price and no more."),
        add: gettext("Add a fee"),
        edit: gettext("Edit this fee"),
        stackable?: false
      }
    ]
  end

  defp section(key), do: Enum.find(sections(), &(&1.key == key))

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:currency, Setting.get(:currency))
     |> assign(:editing, %{seller: nil, buyer: nil})
     |> load_rows()
     |> assign_forms()}
  end

  defp load_rows(socket) do
    actor = socket.assigns.current_scope.user

    assign(socket, :rows, %{
      seller: Payments.list_seller_deductions!(actor: actor),
      buyer: Payments.list_buyer_fees!(actor: actor)
    })
  end

  defp assign_forms(socket) do
    assign(socket, :forms, Map.new(sections(), &{&1.key, form_for(socket, &1)}))
  end

  defp form_for(socket, section) do
    opts = [
      actor: socket.assigns.current_scope.user,
      as: section.as,
      transform_params: &to_stored/2,
      transform_errors: &readable/2
    ]

    case socket.assigns.editing[section.key] do
      nil -> AshPhoenix.Form.for_create(resource(section.key), :add, opts)
      row -> AshPhoenix.Form.for_update(row, :edit, opts)
    end
    |> to_form()
  end

  defp resource(:seller), do: SellerDeduction
  defp resource(:buyer), do: BuyerFee

  # An operator types an amount in major units and a rate as a percentage; both
  # are stored as integers. Converted on the way to the changeset so validating
  # and saving both get it, and the form keeps what was typed to render back.
  #
  # The field the chosen kind does not use is emptied rather than left alone: a
  # row switched from a percentage to a flat amount would otherwise keep the
  # rate it no longer has any use for.
  defp to_stored(%{"kind" => "flat"} = params, _kind) do
    params
    |> Map.put("amount", read(params["amount"], &Money.to_minor/1))
    |> Map.put("rate_bp", nil)
    |> Map.put("of_id", nil)
  end

  defp to_stored(%{"kind" => "percentage"} = params, _kind) do
    params
    |> Map.put("amount", nil)
    |> Map.put("rate_bp", read(params["rate_bp"], &Money.to_basis_points/1))
    |> Map.put("of_id", blank_to_nil(params["of_id"]))
  end

  defp to_stored(params, _kind), do: params

  # What could not be read is passed through as typed, so it is refused as the
  # number it is not rather than arriving as a field the operator left blank.
  defp read(typed, reader) when is_binary(typed) do
    case reader.(typed) do
      {:ok, value} -> value
      :error -> typed
    end
  end

  defp read(typed, _reader), do: typed

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  # A value that could not be read never reaches the attribute as a number, so
  # Ash refuses it as the wrong sort of thing and says only that it is invalid.
  # The operator typed an amount or a percentage, so they are shown one instead.
  defp readable(_changeset, %{field: :amount, message: "is invalid"}) do
    [{:amount, "must be an amount, like 1.99", []}]
  end

  defp readable(_changeset, %{field: :rate_bp, message: "is invalid"}) do
    [{:rate_bp, "must be a percentage, like 2.5", []}]
  end

  defp readable(_changeset, error), do: error

  @impl true
  def handle_event("validate", params, socket) do
    {section, typed} = section_params(params)
    form = AshPhoenix.Form.validate(socket.assigns.forms[section.key], typed)

    {:noreply, assign(socket, :forms, Map.put(socket.assigns.forms, section.key, form))}
  end

  def handle_event("save", params, socket) do
    {section, typed} = section_params(params)

    case AshPhoenix.Form.submit(socket.assigns.forms[section.key], params: typed) do
      {:ok, _row} ->
        {:noreply,
         socket
         |> put_flash(:info, saved(section))
         |> stop_editing(section.key)}

      # The fields carry the detail. The flash is there because the operator
      # pressed something and would otherwise be told nothing by nothing
      # happening.
      {:error, form} ->
        {:noreply,
         socket
         |> assign(:forms, Map.put(socket.assigns.forms, section.key, form))
         |> put_flash(:error, refused(section))}
    end
  end

  def handle_event("edit", %{"section" => key, "id" => id}, socket) do
    key = String.to_existing_atom(key)
    row = Enum.find(socket.assigns.rows[key], &(&1.id == id))

    {:noreply,
     socket
     |> assign(:editing, Map.put(socket.assigns.editing, key, row))
     |> assign_forms()}
  end

  def handle_event("cancel", %{"section" => key}, socket) do
    {:noreply, stop_editing(socket, String.to_existing_atom(key))}
  end

  def handle_event("remove", %{"section" => key, "id" => id}, socket) do
    key = String.to_existing_atom(key)
    row = Enum.find(socket.assigns.rows[key], &(&1.id == id))

    case remove(key, row, socket.assigns.current_scope.user) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, removed(section(key)))
         |> stop_editing(key)}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, undroppable(section(key)))}
    end
  end

  defp remove(_key, nil, _actor), do: {:error, :gone}
  defp remove(:seller, row, actor), do: Payments.remove_seller_deduction(row, actor: actor)
  defp remove(:buyer, row, actor), do: Payments.remove_buyer_fee(row, actor: actor)

  # The form goes back to adding, and the row an edit was abandoned on is read
  # fresh: what is on the page after a save is what is stored, not what was
  # typed to get there.
  defp stop_editing(socket, key) do
    socket
    |> assign(:editing, Map.put(socket.assigns.editing, key, nil))
    |> load_rows()
    |> assign_forms()
  end

  # Each form names itself after its section, so which section an event came
  # from is read off the params rather than carried in the event name.
  defp section_params(params) do
    section = Enum.find(sections(), &Map.has_key?(params, &1.as))

    {section, Map.fetch!(params, section.as)}
  end

  # One whole message per outcome, chosen by the section: a sentence with the
  # noun spliced in only reads correctly in the language it was written for.
  defp saved(%{key: :seller}), do: gettext("That deduction has been saved.")
  defp saved(%{key: :buyer}), do: gettext("That fee has been saved.")

  defp refused(%{key: :seller}), do: gettext("That deduction could not be saved.")
  defp refused(%{key: :buyer}), do: gettext("That fee could not be saved.")

  defp removed(%{key: :seller}), do: gettext("That deduction has been removed.")
  defp removed(%{key: :buyer}), do: gettext("That fee has been removed.")

  defp undroppable(%{key: :seller}),
    do: gettext("That deduction stays while another deduction is a percentage of it.")

  defp undroppable(%{key: :buyer}), do: gettext("That fee could not be removed.")

  # What a field shows before anybody has typed in it: the row being edited,
  # rendered the way it was typed rather than the way it is stored.
  defp typed(form, key), do: Map.get(form.params, to_string(key))

  defp value(form, row, :amount), do: typed(form, :amount) || Money.amount(row && row.amount)
  defp value(form, row, :rate_bp), do: typed(form, :rate_bp) || Money.rate(row && row.rate_bp)

  defp value(form, row, :kind) do
    typed(form, :kind) || to_string((row && row.kind) || :flat)
  end

  defp value(form, row, key), do: typed(form, key) || (row && Map.get(row, key))

  defp kinds do
    [{gettext("A flat amount"), "flat"}, {gettext("A percentage"), "percentage"}]
  end

  # Every other row is offerable as what this one is a percentage of. A chain
  # that closes on itself is refused on save rather than hidden here: which
  # rows would close one depends on the whole table, and an option quietly
  # missing explains nothing.
  defp bases(rows, editing) do
    for row <- rows, editing == nil or row.id != editing.id, do: {row.name, row.id}
  end

  defp shown(%{kind: :flat, amount: amount}, currency), do: Money.format(amount, currency)
  defp shown(%{rate_bp: rate_bp}, _currency), do: Money.percent(rate_bp)

  defp basis(%{of_id: nil}, _rows), do: gettext("Sale price")

  defp basis(%{of_id: of_id}, rows) do
    case Enum.find(rows, &(&1.id == of_id)) do
      nil -> gettext("Sale price")
      row -> row.name
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      categories={@search_categories}
      cart_count={@cart_count}
      flash={@flash}
      current_scope={@current_scope}
      current_path={~p"/admin/fees"}
    >
      <div class="flex flex-col gap-6">
        <.breadcrumb items={[%{label: gettext("Admin")}, %{label: gettext("Fees")}]} />

        <.header>
          {gettext("Fees and deductions")}
          <:subtitle>
            {gettext("What the marketplace takes from a sale, and what it adds to one.")}
          </:subtitle>
        </.header>
      </div>

      <div class="flex flex-col items-center gap-8 max-w-[720px] mx-auto py-8">
        <.card :for={section <- sections()} class="w-full flex flex-col gap-5">
          <div>
            <h2 class="text-title-lg font-bold text-ink-900">{section.title}</h2>
            <p class="text-caption-lg text-ink-500 mt-0.5">{section.hint}</p>
          </div>

          <p
            :if={@rows[section.key] == []}
            id={"#{section.dom}s-empty"}
            class="text-body-sm text-ink-500"
          >
            {section.empty}
          </p>

          <.table
            :if={@rows[section.key] != []}
            id={"#{section.dom}s"}
            rows={@rows[section.key]}
            caption={section.title}
            row_id={&"#{section.dom}-#{&1.id}"}
          >
            <:col :let={row} label={gettext("Name")} row_header>{row.name}</:col>
            <:col :let={row} label={gettext("Takes")}>{shown(row, @currency)}</:col>
            <:col :let={row} :if={section.stackable?} label={gettext("Of")}>
              {basis(row, @rows[section.key])}
            </:col>
            <:action :let={row}>
              <button
                id={"edit-#{section.dom}-#{row.id}"}
                type="button"
                phx-click="edit"
                phx-value-section={section.key}
                phx-value-id={row.id}
                class="text-body-sm font-semibold text-primary-700 hover:text-primary-600 underline cursor-pointer"
              >
                {gettext("Edit")}
              </button>
              <button
                id={"remove-#{section.dom}-#{row.id}"}
                type="button"
                phx-click="remove"
                phx-value-section={section.key}
                phx-value-id={row.id}
                class="text-body-sm font-semibold text-error hover:opacity-80 underline cursor-pointer"
              >
                {gettext("Remove")}
              </button>
            </:action>
          </.table>

          <.form
            :let={form}
            id={"#{section.dom}-form"}
            for={@forms[section.key]}
            phx-change="validate"
            phx-submit="save"
            class="flex flex-col gap-5 pt-2 border-t border-ink-100 dark:border-ink-700"
          >
            <h3 class="text-title-md font-bold text-ink-900">
              {if @editing[section.key], do: section.edit, else: section.add}
            </h3>

            <.input
              field={form[:name]}
              type="text"
              value={value(@forms[section.key], @editing[section.key], :name)}
              label={gettext("Name")}
            />

            <.input
              field={form[:kind]}
              type="select"
              value={value(@forms[section.key], @editing[section.key], :kind)}
              options={kinds()}
              label={gettext("Takes")}
            />

            <.input
              :if={value(@forms[section.key], @editing[section.key], :kind) == "flat"}
              field={form[:amount]}
              type="text"
              inputmode="decimal"
              value={value(@forms[section.key], @editing[section.key], :amount)}
              placeholder="0.00"
              label={gettext("Amount (%{symbol})", symbol: Money.symbol(@currency))}
            />

            <.input
              :if={value(@forms[section.key], @editing[section.key], :kind) == "percentage"}
              field={form[:rate_bp]}
              type="text"
              inputmode="decimal"
              value={value(@forms[section.key], @editing[section.key], :rate_bp)}
              placeholder="0"
              label={gettext("Percentage (%)")}
            />

            <.input
              :if={
                section.stackable? and
                  value(@forms[section.key], @editing[section.key], :kind) == "percentage"
              }
              field={form[:of_id]}
              type="select"
              value={value(@forms[section.key], @editing[section.key], :of_id)}
              prompt={gettext("Sale price")}
              options={bases(@rows[section.key], @editing[section.key])}
              label={gettext("Of")}
            />

            <div class="flex gap-3">
              <.button
                type="submit"
                variant="primary"
                full_width
                phx-disable-with={gettext("Saving…")}
              >
                {if @editing[section.key], do: section.edit, else: section.add}
              </.button>
              <.button
                :if={@editing[section.key]}
                id={"cancel-#{section.dom}"}
                type="button"
                variant="secondary"
                phx-click="cancel"
                phx-value-section={section.key}
              >
                {gettext("Cancel")}
              </.button>
            </div>
          </.form>
        </.card>
      </div>
    </Layouts.app>
    """
  end
end
