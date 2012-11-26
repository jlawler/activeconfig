ActiveConfig
============


1. In your gemfile:
    
    gem 'therubyracer';
    gem 'activeconfig'
    
2. On the command line:

    rails generate active_config:install

3. Create etc/defaults.yml and insert:

    environmental_var: "foo"

4. Create etc/defaults_production.yml and insert

    environmental_var: "bar"

5. Run this code in development:

    CONF.defaults.environmental_var

You will get "foo"

6. Run this code in production:

    CONF.defaults.environment_var

And get "bar"

What is it?
-----------

An extremely flexible configuration system. Gives the ability for certain values to be overridden when conditions are met. For example, you could have your production API keys only get read when the Rails.env == production.

Specifically, you can create yaml files filled with key-value pairs in the etc directory, and the variables you set there will be accessible in code via CONF.<filename>, which is a hash representing the key-value pairs in the file. Note that it allows for environment specialization: defaults.yml will be used to populate CONF.defaults in development, so will defaults_development.yml, but defaults_production.yml will be used in production.


What other cool things does it do?
----------------------------------
Moves your database.yml into the etc folder.

Author Jordan Prince

License
MIT/X11
