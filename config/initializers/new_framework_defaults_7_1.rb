# Be sure to restart your server when you modify this file.
#
# This file eases your Rails 7.1 framework defaults upgrade.
#
# Uncomment each configuration one by one to switch to the new default.
# Once your application is ready to run with all new defaults, you can remove
# this file and set the `config.load_defaults` to `7.1`.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.
# https://guides.rubyonrails.org/upgrading_ruby_on_rails.html
#
# This is the stock template Rails ships via `rails app:update` for the 7.1
# hop (fetched verbatim from the `railties-8.0.5` gem installed for this hop
# via Gemfile.next -- Task 9 lands Rails 7.1/7.2/8.0 as one combined hop
# rather than stopping at each intermediate minor, per the roadmap's own
# grouping, but still walks each minor's individually-togglable defaults
# separately below, the same way Tasks 6/7/8 did one minor at a time). Per
# the roadmap's risk-tiered `load_defaults` ramp, every behavior below stays
# commented out / pinned to its pre-7.1 default UNLESS noted otherwise --
# audit results below.

# No longer add autoloaded paths into `$LOAD_PATH`.
# Not flipped -- this app requires `lib/` files explicitly (Task 6's own
# audit), so nothing relies on `$LOAD_PATH`-based implicit requires of
# autoloaded paths, but there's no forcing function to flip it either;
# deferred rather than bundled into this hop.
# Rails.application.config.add_autoload_paths_to_load_path = false

# Remove the default X-Download-Options headers since it is used only by IE.
# Not flipped -- same reasoning as the 7.0 hop's `default_headers` deferral;
# no test asserts on this header, no forcing function.
# Rails.application.config.action_dispatch.default_headers = { ... }

# Do not treat an `ActionController::Parameters` instance as equal to an
# equivalent `Hash` by default.
# Not flipped -- grepped app/ and test/ for `params == {...}`/`{...} ==
# params` style Hash-equality comparisons; none found, so this is a no-op
# either way, but leaving it pinned avoids any latent behavior surprise this
# hop didn't set out to audit.
# Rails.application.config.action_controller.allow_deprecated_parameters_hash_equality = false

# Active Record Encryption SHA-256 hash digest / non-deterministic support.
# N/A -- this app doesn't use Active Record Encryption (confirmed again this
# hop: no `encrypts` declarations anywhere in app/models).
# Rails.application.config.active_record.encryption.hash_digest_class = ...
# Rails.application.config.active_record.encryption.support_sha1_for_non_deterministic_encryption = false

# No longer run after_commit callbacks on the first of multiple AR instances
# saving the same row in a transaction; run on the last instance instead.
# Not flipped -- would change callback-ordering semantics for any code path
# that loads/saves the same row twice in one transaction (e.g. `Okr#save`'s
# `update_children` cascade touches Objective/KeyResult rows saved via
# `accepts_nested_attributes_for`, a plausible multi-instance-per-row
# scenario); auditing every after_commit callback against this is a
# deliberate future follow-up, not bundled into this hop.
# Rails.application.config.active_record.run_commit_callbacks_on_first_saved_instances_in_transaction = false

# SQLite strict strings mode.
# N/A -- this app uses mysql2, not sqlite3.
# Rails.application.config.active_record.sqlite3_adapter_strict_strings_by_default = true

# Disable deprecated singular associations names.
# Not flipped -- no forcing function; this app's associations were never
# audited against this specific deprecation.
# Rails.application.config.active_record.allow_deprecated_singular_associations_name = false

# Enable the Active Job BigDecimal argument serializer.
# N/A -- this app has no ActiveJob-backed background job usage (confirmed
# again this hop via grep, same finding as Tasks 6/7/8).
# Rails.application.config.active_job.use_big_decimal_serializer = true

# Raise ArgumentError on invalid Rails.cache expiration times.
# N/A -- this app doesn't use `Rails.cache` (confirmed again this hop via
# grep, same finding as Tasks 6/7/8).
# Rails.application.config.active_support.raise_on_invalid_cache_expiration_time = true

# Query Logs SQLCommenter format.
# Not flipped -- this app doesn't have query log tags configured at all
# (grepped config/ for `query_log_tags`); N/A either way.
# Rails.application.config.active_record.query_log_tags_format = :sqlcommenter

# MessageEncryptor/MessageVerifier default serializer.
# Not flipped -- this app doesn't configure custom MessageEncryptor/Verifier
# instances directly; Rails' own signed cookies/sessions use whatever the
# framework default is, and changing the message-serializer format
# mid-upgrade-ladder (more Rails hops still to come after this one, though
# this IS the last per the roadmap) risks invalidating in-flight signed
# cookies across a deploy. Deferred as a deliberate follow-up outside this
# hop's scope, same reasoning as the 7.0 hop's cache-format-version deferral.
# Rails.application.config.active_support.message_serializer = :json_allow_marshal

# Serialize message data and metadata together (performance optimization).
# Not flipped -- same rolling-deploy-safety reasoning as the message
# serializer above; deferred.
# Rails.application.config.active_support.use_message_serializer_for_metadata = true

# Maximum Rails log file size (dev/test only).
# Not flipped -- no forcing function; this app's log files were never an
# observed problem.
# if Rails.env.local?
#   Rails.application.config.log_file_size = 100 * 1024 * 1024
# end

# Raise on assignment to attr_readonly attributes (previously silently
# allowed but not persisted).
# Not flipped -- grepped app/models for `attr_readonly`; none declared
# anywhere in this app, so this is a no-op either way.
# Rails.application.config.active_record.raise_on_assign_to_attr_readonly = true

# Validate only parent-related columns for presence when parent is mandatory.
# N/A -- this app explicitly sets
# `config.active_record.belongs_to_required_by_default = false` (see
# config/application.rb, from the 4.2 -> 5.0 hop), so mandatory-parent
# presence validation was never opted into in the first place; this toggle
# has nothing to change.
# Rails.application.config.active_record.belongs_to_required_validates_foreign_key = false

# Precompile `config.filter_parameters`.
# Not flipped -- pure performance optimization, no behavior change either
# way; no forcing function to opt in during this hop.
# Rails.application.config.precompile_filter_parameters = true

# Run before_committed! callbacks on all enrolled records in a transaction.
# Not flipped -- same multi-instance-per-row callback-ordering reasoning as
# `run_commit_callbacks_on_first_saved_instances_in_transaction` above;
# deferred together.
# Rails.application.config.active_record.before_committed_on_all_records = true

# Disable automatic column serialization into YAML.
# Not flipped -- grepped app/models for `serialize :column`; none declared
# anywhere in this app, so this is a no-op either way.
# Rails.application.config.active_record.default_column_serializer = nil

# Faster/more compact Active Record model marshalling format (rolling-deploy
# caveat, same as the message serializer above).
# Not flipped -- deferred, same rolling-deploy-safety reasoning.
# Rails.application.config.active_record.marshalling_format_version = 7.1

# Run after_commit/after_*_commit callbacks in definition order (was reverse).
# Not flipped -- auditing every model's after_commit callback ordering
# against this is a deliberate future follow-up, not bundled into this hop
# (same class of risk as the other transaction-callback toggles above).
# Rails.application.config.active_record.run_after_transaction_callbacks_in_order_defined = true

# Whether a `transaction` block commits or rolls back on `return`/`break`/`throw`.
# Not flipped -- grepped app/models and app/controllers for `transaction do`
# blocks using `return`/`break`/`throw` inside; none found, so this is a
# no-op either way, but leaving it pinned avoids a latent surprise this hop
# didn't set out to audit.
# Rails.application.config.active_record.commit_transaction_on_non_local_return = true

# When `has_secure_token` generates its token value.
# N/A -- grepped app/models for `has_secure_token`; none declared anywhere
# in this app.
# Rails.application.config.active_record.generate_secure_token_on = :initialize

# ** Must be configured in config/application.rb, NOT this file **
# Change the cache entry format (breaks compat with pre-7.1 readers).
# Not flipped -- same reasoning as the 7.0 hop's cache-format-version
# deferral (no shared production cache store in this repo to worry about a
# rolling deploy for, but no upside to churning it either).
# config.active_support.cache_format_version = 7.1

# HTML5-standards-compliant sanitizer vendor for Action View.
# Not flipped -- this app's views were built and characterization-tested
# against the HTML4 sanitizer's exact output; switching sanitizer vendors is
# exactly the kind of behavior change this roadmap's hops defer unless
# forced. No CVE/incompatibility hit with the HTML4 vendor under Rails
# 7.1/7.2/8.0 (rails-html-sanitizer 1.7.0, unchanged this hop).
# Rails.application.config.action_view.sanitizer_vendor = Rails::HTML::Sanitizer.best_supported_vendor

# Same HTML5-sanitizer-vendor toggle for Action Text.
# N/A -- this app doesn't use Action Text (no `has_rich_text` declarations
# anywhere in app/models).
# Rails.application.config.action_text.sanitizer_vendor = Rails::HTML::Sanitizer.best_supported_vendor

# Log level for DebugExceptions middleware logging uncaught exceptions.
# Not flipped -- no forcing function; this app's exception-logging behavior
# in dev/test was never an observed problem.
# Rails.application.config.action_dispatch.debug_exception_log_level = :error

# HTML5 parsers for Action View/Action Dispatch/rails-dom-testing test helpers.
# Not flipped -- same reasoning as the sanitizer-vendor toggle above: this
# app's ~230 view templates and their controller/integration tests were
# characterized against the HTML4 parser's exact assertion behavior
# (`assert_select`, etc. -- though this app's own tests don't happen to use
# `assert_select`, grepped and confirmed). No forcing function to switch
# parsers mid-upgrade-ladder.
# Rails.application.config.dom_testing_default_html_version = :html5
