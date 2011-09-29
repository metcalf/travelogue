# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_travelogue_session',
  :secret      => 'f42a9d56a6f111e270b7bb1af8c446a47d7f164690f1350f5e80510f7ecbbee26638e8c2aa31a7de2197f83444d76945a57a77fb01babf8410a42c931ed84c6e'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
