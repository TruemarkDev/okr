# Be sure to restart your server when you modify this file.
#
# This file contains migration options to ease your Rails 6.1 upgrade.
#
# Once upgraded flip defaults one by one to migrate to the new default.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.
#
# This is the stock template Rails ships via `rails app:update` for the 6.1
# hop (fetched verbatim from the `railties-6.1.7.10` gem installed for this
# hop via Gemfile.next, the same way Task 6 pulled the 6.0 template — see
# config/initializers/new_framework_defaults_6_0.rb). Per the roadmap's
# risk-tiered `load_defaults` ramp, this hop (Task 7) only turns on
# `config.load_defaults 6.1` itself (guarded by `NextRails.next?` in
# config/application.rb) and leaves every individually-togglable behavior
# below commented out / pinned to its pre-6.1 default. None of them are
# exercised by this app's current code (no `form_with`, ActiveStorage,
# multiple-database connection handling, or CSRF/cookie SameSite hardening
# was found — see the audit below), so there's no forcing function to flip
# any of them yet.

# Support for inversing belongs_to -> has_many Active Record associations.
# Not enabled: this app's associations were never audited against
# `has_many_inversing` semantics (it changes which in-memory object a loaded
# child association points back to); flipping it is a deliberate future
# audit, not a side effect of this hop.
# Rails.application.config.active_record.has_many_inversing = true

# Track Active Storage variants in the database.
# N/A — this app doesn't use ActiveStorage (CarrierWave/MiniMagick handle
# uploads instead; see app/uploaders/). No `has_many_attached`/
# `has_one_attached`/`ActiveStorage::` references found anywhere in app/.
# Rails.application.config.active_storage.track_variants = true

# Apply random variation to the delay when retrying failed jobs.
# N/A — this app has no ActiveJob-backed background job usage that retries.
# Rails.application.config.active_job.retry_jitter = 0.15

# Stop executing `after_enqueue`/`after_perform` callbacks if
# `before_enqueue`/`before_perform` respectively halts with `throw :abort`.
# N/A — same reason as above, no ActiveJob callback usage in this app.
# Rails.application.config.active_job.skip_after_callbacks_if_terminated = true

# Specify cookies SameSite protection level: either :none, :lax, or :strict.
#
# This change is not backwards compatible with earlier Rails versions.
# It's best enabled when your entire app is migrated and stable on 6.1.
# Not flipped this hop — Turbolinks 2.x/jquery-turbolinks (classic, non-Turbo)
# session/cookie behavior wasn't audited against SameSite=:lax; leave pinned
# to Rails' pre-6.1 default (no explicit same-site attribute) for now.
# Rails.application.config.action_dispatch.cookies_same_site_protection = :lax

# Generate CSRF tokens that are encoded in URL-safe Base64.
#
# This change is not backwards compatible with earlier Rails versions.
# It's best enabled when your entire app is migrated and stable on 6.1.
# Rails.application.config.action_controller.urlsafe_csrf_tokens = true

# Specify whether `ActiveSupport::TimeZone.utc_to_local` returns a time with an
# UTC offset or a UTC time.
# N/A — grepped app/ and lib/ for `utc_to_local`, no direct callers found.
# ActiveSupport.utc_to_local_returns_utc_offset_times = true

# Change the default HTTP status code to `308` when redirecting non-GET/HEAD
# requests to HTTPS in `ActionDispatch::SSL` middleware.
# N/A — this app doesn't force SSL redirects via `config.force_ssl` in any
# environment checked; no observed behavior to change.
# Rails.application.config.action_dispatch.ssl_default_redirect_status = 308

# Use new connection handling API. For most applications this won't have any
# effect. For applications using multiple databases, this new API provides
# support for granular connection swapping.
# N/A — single `config/database.yml` per environment, no multi-DB/replica
# setup (see Gemfile.next's scaffold comment for this hop).
# Rails.application.config.active_record.legacy_connection_handling = false

# Make `form_with` generate non-remote forms by default.
# Not flipped — this app's ERB views still use classic `form_for`/`form_tag`
# plus jQuery-UJS/Turbolinks-driven remote submits in places; auditing every
# form for a `local:`/remote-submit dependency is a deliberate future
# follow-up, not in scope for this "usually smooth" minor-version hop.
# Rails.application.config.action_view.form_with_generates_remote_forms = false

# Set the default queue name for the analysis job to the queue adapter default.
# N/A — no ActiveStorage usage (see above).
# Rails.application.config.active_storage.queues.analysis = nil

# Set the default queue name for the purge job to the queue adapter default.
# N/A — no ActiveStorage usage (see above).
# Rails.application.config.active_storage.queues.purge = nil

# Set the default queue name for the incineration job to the queue adapter default.
# N/A — this app doesn't use ActionMailbox.
# Rails.application.config.action_mailbox.queues.incineration = nil

# Set the default queue name for the routing job to the queue adapter default.
# N/A — this app doesn't use ActionMailbox.
# Rails.application.config.action_mailbox.queues.routing = nil

# Set the default queue name for the mail deliver job to the queue adapter default.
# N/A — mail is delivered synchronously in this app (no `deliver_later`
# usage found); nothing to route to a named queue.
# Rails.application.config.action_mailer.deliver_later_queue_name = nil

# Generate a `Link` header that gives a hint to modern browsers about
# preloading assets when using `javascript_include_tag` and `stylesheet_link_tag`.
# Not flipped — no observed need, and this app's Sprockets/asset-pipeline
# setup wasn't audited against HTTP/2 Link-header preload behavior.
# Rails.application.config.action_view.preload_links_header = true
