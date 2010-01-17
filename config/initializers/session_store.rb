# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_blup_session',
  :secret      => 'f827acfcd653f74f8f44caeb01532bfefca4210e291b482639959400e46d3b2e9cc1338df928aa5cb9fc4d7feb3813eae6aafd1ab26da14ed1f66ca81657da4d'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
