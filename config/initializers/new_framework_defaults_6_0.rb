# Be sure to restart your server when you modify this file.
#
# This file contains migration options to ease your Rails 6.0 upgrade.
#
# Once upgraded flip defaults one by one to migrate to the new default.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.
#
# This is the stock template Rails ships via `rails app:update` for the 6.0
# hop (fetched from the `v6.0.6.1` tag rather than hand-written, so the
# comments/options match upstream exactly). Per the roadmap's risk-tiered
# `load_defaults` ramp ("walk the toggles one at a time, don't flip
# wholesale"), roadmap Task 6 (this hop) only turns on Zeitwerk itself via
# `config.load_defaults 6.0` (guarded by `NextRails.next?` in
# config/application.rb) and leaves every item below commented out — i.e.
# every one of these individually-togglable Rails 6.0 behavior changes stays
# pinned to its pre-6.0 behavior for now. None of them are exercised by this
# app's current code/tests (no `form_with`/cookie-metadata/ActiveStorage/
# ActionMailer background delivery/collection-cache-versioning usage was
# found), so there's no forcing function to flip any of them yet. Future
# hops (or a deliberate follow-up) can enable individual lines here once
# each is reviewed against this app's behavior.

# Don't force requests from old versions of IE to be UTF-8 encoded.
# Rails.application.config.action_view.default_enforce_utf8 = false

# Embed purpose and expiry metadata inside signed and encrypted
# cookies for increased security.
#
# This option is not backwards compatible with earlier Rails versions.
# It's best enabled when your entire app is migrated and stable on 6.0.
# Rails.application.config.action_dispatch.use_cookies_with_metadata = true

# Change the return value of `ActionDispatch::Response#content_type` to Content-Type header without modification.
# Rails.application.config.action_dispatch.return_only_media_type_on_content_type = false

# Return false instead of self when enqueuing is aborted from a callback.
# Rails.application.config.active_job.return_false_on_aborted_enqueue = true

# Send Active Storage analysis and purge jobs to dedicated queues.
# Rails.application.config.active_storage.queues.analysis = :active_storage_analysis
# Rails.application.config.active_storage.queues.purge    = :active_storage_purge

# When assigning to a collection of attachments declared via `has_many_attached`, replace existing
# attachments instead of appending. Use #attach to add new attachments without replacing existing ones.
# Rails.application.config.active_storage.replace_on_assign_to_many = true

# Use ActionMailer::MailDeliveryJob for sending parameterized and normal mail.
#
# The default delivery jobs (ActionMailer::Parameterized::DeliveryJob, ActionMailer::DeliveryJob),
# will be removed in Rails 6.1. This setting is not backwards compatible with earlier Rails versions.
# If you send mail in the background, job workers need to have a copy of
# MailDeliveryJob to ensure all delivery jobs are processed properly.
# Make sure your entire app is migrated and stable on 6.0 before using this setting.
# Rails.application.config.action_mailer.delivery_job = "ActionMailer::MailDeliveryJob"

# Enable the same cache key to be reused when the object being cached of type
# `ActiveRecord::Relation` changes by moving the volatile information (max updated at and count)
# of the relation's cache key into the cache version to support recycling cache key.
# Rails.application.config.active_record.collection_cache_versioning = true
