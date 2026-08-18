defmodule MercatoWeb.AuthOverrides do
  @moduledoc """
  UI overrides for the generated `ash_authentication_phoenix` components,
  restyled to match Mercato's design system
  (see docs/architecture/ui-components.md, design-tokens.md).

  `MercatoWeb.Live.Auth.RegisterForm`/`SignInForm`/`ResetForm` each embed a
  Password/Magic-link segmented control directly (see
  `MercatoWeb.Live.Auth.Styles.mode_switcher/1`), submitting to whichever
  action the active tab needs. That supersedes the library's own
  `AshAuthentication.Phoenix.Components.MagicLink` section (always rendered
  once per resource, independent of `first_name`/register/sign-in state) —
  it's hidden below rather than left to render a redundant, separately-boxed
  copy of the same "email me a link" flow.
  """

  use AshAuthentication.Phoenix.Overrides

  override AshAuthentication.Phoenix.SignInLive do
    set :root_class, "grid min-h-screen place-items-center bg-bg-2 dark:bg-ink-900 py-12"
  end

  override AshAuthentication.Phoenix.Components.SignIn do
    set :root_class, "mx-auto w-full max-w-md px-4"
    set :strategy_class, "mb-4"
    set :authentication_error_container_class, "text-error-text text-center mb-4"
    set :authentication_error_text_class, "text-body-sm"
    set :strategy_display_order, :forms_first
  end

  override AshAuthentication.Phoenix.Components.Banner do
    set :root_class, "w-full flex items-center justify-center gap-2 py-6"
    set :href_url, "/"
    set :href_class, nil
    set :image_class, "h-8 w-8"
    set :dark_image_class, "hidden"
    set :image_url, "/images/mercato-logo.png"
    set :dark_image_url, nil
    set :text_class, "text-[24px] font-extrabold text-ink-900 dark:text-white"
    set :text, "Mercato"
  end

  # The "or" divider only ever separated the form-style strategies (password)
  # from the link-style ones (magic link) — now that magic link lives inside
  # each form's own tab, there's nothing left for it to separate.
  override AshAuthentication.Phoenix.Components.HorizontalRule do
    set :root_class, "hidden"
  end

  override AshAuthentication.Phoenix.Components.Password do
    set :root_class, nil
    set :interstitial_class, "flex flex-row justify-between text-body-sm mt-4"
    set :toggler_class, "text-primary-700 hover:text-primary-600 font-medium"
    set :sign_in_toggle_text, "Already have an account? Log in"
    set :register_toggle_text, "Need an account? Sign up"
    set :reset_toggle_text, "Forgot your password?"
    set :show_first, :sign_in
    set :hide_class, "hidden"
    set :register_form_module, MercatoWeb.Live.Auth.RegisterForm
    set :sign_in_form_module, MercatoWeb.Live.Auth.SignInForm
    set :reset_form_module, MercatoWeb.Live.Auth.ResetForm
  end

  # `Password.Input` (identity/password fields, generic submit button) has no
  # remaining caller: RegisterForm/SignInForm/ResetForm render their own
  # fields via core `<.input>` directly, and `Components.MagicLink` below (the
  # only other component that used it) is hidden. Nothing left to override it
  # for.
  override AshAuthentication.Phoenix.Components.MagicLink do
    set :root_class, "hidden"
  end

  # Styles the confirmation-page button at /auth/:subject_name/magic_link/:token
  # (opened from the emailed link) — the sole action on that page, so it stays
  # primary.
  override AshAuthentication.Phoenix.Components.MagicLink.Input do
    set :submit_class,
        "rounded-md shadow-sm font-semibold hover:brightness-95 transition-colors w-full h-[52px] bg-primary-500 text-white"

    set :input_debounce, 350
    set :remember_me_class, "flex items-center gap-2 mt-2 mb-2"
    set :remember_me_input_label, "Remember me"
    set :checkbox_class, "mr-2"
    set :checkbox_label_class, "text-body-sm text-ink-700"
    set :submit_label, "Sign in"
  end
end
