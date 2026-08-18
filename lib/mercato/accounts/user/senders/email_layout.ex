defmodule Mercato.Accounts.User.Senders.EmailLayout do
  @moduledoc """
  Shared HTML wrapper for transactional emails, styled to match Mercato's
  design tokens (see docs/architecture/design-tokens.md) with inline styles
  for email-client compatibility.
  """

  @doc """
  Wraps `heading`/`paragraphs` in the branded layout with a primary CTA
  button linking to `cta_url`, and an optional `footer` note below it.
  """
  def render(heading, paragraphs, cta_label, cta_url, footer \\ nil) do
    """
    <div style="background:#F5F5F5;padding:32px 16px;font-family:-apple-system,'Segoe UI',Helvetica,Arial,sans-serif;">
      <div style="max-width:480px;margin:0 auto;background:#FFFFFF;border:1px solid #E5E5EA;border-radius:12px;padding:32px;">
        <div style="font-size:18px;font-weight:800;color:#1C1C1E;margin:0 0 24px;">Mercato</div>
        <h1 style="font-size:20px;font-weight:700;color:#1C1C1E;margin:0 0 12px;">#{heading}</h1>
        #{Enum.map_join(paragraphs, "", &paragraph/1)}
        <a href="#{cta_url}" style="display:inline-block;background:#3B82F6;color:#FFFFFF;font-weight:600;font-size:15px;text-decoration:none;padding:12px 24px;border-radius:8px;margin:8px 0 16px;">#{cta_label}</a>
        <p style="font-size:13px;color:#8E8E93;word-break:break-all;margin:0 0 16px;">Or copy this link: <a href="#{cta_url}" style="color:#8E8E93;">#{cta_url}</a></p>
        #{footer_html(footer)}
      </div>
    </div>
    """
  end

  defp paragraph(text) do
    ~s(<p style="font-size:15px;line-height:1.5;color:#3A3A3C;margin:0 0 16px;">#{text}</p>)
  end

  defp footer_html(nil), do: ""

  defp footer_html(text) do
    ~s(<p style="font-size:13px;color:#8E8E93;margin:24px 0 0;">#{text}</p>)
  end
end
