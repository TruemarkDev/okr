# Turbolinks 2.5.4 (unmaintained since ~2015) blocks cross-origin redirects via an
# after_action callback, Turbolinks::XDomainBlocker#abort_xdomain_redirect ->
# same_origin?, which calls URI.escape -- removed entirely in Ruby 3.0. It only
# fires when the response redirects (Location header present) AND the request
# carries Turbolinks' own X-XHR-Referer header (set by Turbolinks-driven
# link/form navigation), so a raw curl/direct-HTTP request never trips it -- but
# any "create/update and redirect" flow reached through a real link/form click
# crashed with `NoMethodError: undefined method 'escape' for module URI`.
#
# Re-implementing the same same-origin check with the modern equivalent
# (URI::DEFAULT_PARSER.escape) restores the original behavior without touching
# the vendored gem. Safe to delete if turbolinks-rails is ever upgraded/replaced.
Rails.application.config.to_prepare do
  Turbolinks::XDomainBlocker.module_eval do
    private

    def same_origin?(a, b)
      a = URI.parse(URI::DEFAULT_PARSER.escape(a))
      b = URI.parse(URI::DEFAULT_PARSER.escape(b))
      [a.scheme, a.host, a.port] == [b.scheme, b.host, b.port]
    end
  end
end
