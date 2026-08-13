---
type: architecture
title: Testing
description: Backend and Ash test conventions.
tags: [architecture, testing, ash]
timestamp: 2026-07-23T00:00:00Z
---

Standards for writing backend tests. See also [coding-standards.md](coding-standards.md) and [liveview-testing.md](liveview-testing.md) for LiveView-specific conventions.

## Test guidelines

- **Always use `start_supervised!/1`** to start processes in tests as it guarantees cleanup between tests
- **Avoid** `Process.sleep/1` and `Process.alive?/1` in tests
  - Instead of sleeping to wait for a process to finish, **always** use `Process.monitor/1` and assert on the DOWN message:

    ```elixir
    ref = Process.monitor(pid)
    assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    ```

  - Instead of sleeping to synchronize before the next call, **always** use `_ = :sys.get_state/1` to ensure the process has handled prior messages

## Ash resource tests

- Test domain actions through the code interface (`Mercato.Transactions.checkout/2`, per [principles.md → SRP](principles.md#srp--single-responsibility)) — not by building `Ash.Changeset`s by hand.
- Use `Ash.Test` utilities and the raising action variants (`create!`, `checkout!`) over pattern-matching `{:ok, _}` tuples.
- Test authorization with `Ash.can?/3`. Pass `authorize?: false` in tests where authorization isn't the focus.
- Build fixtures with `Ash.Generator`, not hand-built maps — put reusable generators in a `TestGenerators` module:

  ```elixir
  defmodule Mercato.TestGenerators do
    use Ash.Generator

    def user(opts \\ []) do
      changeset_generator(
        Mercato.Accounts.User,
        :create,
        defaults: [
          email: "user-#{System.unique_integer([:positive])}@example.com",
          handle: "user_#{System.unique_integer([:positive])}"
        ],
        overrides: opts
      )
    end
  end
  ```

- `Ash.Generator` has two constructors — pick based on whether the action's behavior matters to the test:
  - `changeset_generator/3` (above) runs the real action — changes, validations, and policies apply.
  - `seed_generator/2` writes straight to the data layer via `Ash.Seed`, skipping actions entirely — for fast bulk fixtures where only the data's existence matters:

    ```elixir
    def address(opts \\ []) do
      seed_generator(
        {Mercato.Accounts.Address, %{postal_code: sequence(:postal_code, &"#{10_000 + &1}")}},
        overrides: opts
      )
    end
    ```

- Identity attributes (`email`, `handle`, bank account number, etc.) need globally unique values in every test — `System.unique_integer([:positive])`, never a fixed string. Async tests hitting the same unique constraint deadlock in the sandbox.
