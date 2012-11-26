ActiveConfig
============


1. In your gemfile:
    
    gem 'therubyracer'
    gem 'activeconfig'
    
2. On the command line:

    rails generate active_config:install

3. Create etc/defaults.yml:

    environmental_var: "foo"

4. Create etc/defaults_production.yml

    environmental_var: "bar"

5. Run this code in IRB in development:

    CONF.defaults.environmental_var

You will get "foo"

6. Run this code in IRB in production:

    CONF.defaults.environment_var

And get "bar"


An extremely flexible configuration system. Gives the ability for certain values to be overridden when conditions are met. For example, you could have your production API keys only get read when the Rails.env == production

