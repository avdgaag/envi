# Envy [![Build Status](https://secure.travis-ci.org/avdgaag/envy.png?branch=master)](http://travis-ci.org/avdgaag/envy)

Envy is a simple module to define environment variable requirements, and to load
those environment variables into Ruby constants. This is ideal for managing
configuration settings using environment variables, as one would on [Heroku].

Read the [full API documentation][docs] for detailed API and usage instructions.

[docs]: http://rubydoc.info/github/avdgaag/envy
[Heroku]: http://heroku.com

## Installation

Add this line to your application's Gemfile:

    gem 'envy'

And then execute:

    % bundle

Or install it yourself as:

    % gem install envy

## Usage

### The `envars.yml` file

First, define your requirements in a YAML file. By default, Envy will look for
`./config/envars.yml`. For example:

    ---
    &defaults:
      - name: AWS_ACCESS_KEY
        message: Please provide your Amazon AWS credentials as environment variables.
      - name: AWS_ACCESS_SECRET
        message: Please provide your Amazon AWS credentials as environment variables.
      - name: HASHING_SALT
    production:
      <<: *defaults
    development:
      <<: *defaults

You can define your required environment variables by name, and also provide
an optional custom exception message to be used when that variable is not
set.

### Initializing Envy

To read the requirements and inspect the current environment variables,
simply call `Envy.init`. This will raise an exception if requirements are not
met. When working with Rails apps, you might want to use this is an
initializer.

### Providing environment variables in a file

A common pattern is to define custom environment variables in a `.env` file
in your application's root directory. Other gems, such as [Foreman][] will
use such a file to augment the environment before running processes. When in
development mode, Envy can also do this for you. Simply tell it which file to
use:

    Envy.init parse: '.env'

It is a good idea to not include such a file (which commonly contains
application secrets) in source control.

### Extending your Rails application configuration

Envy will expose all the loaded environment variables as constants in the Envy
module, so you can access them as:

    Envy::MY_VARIABLE

You could also opt to extend your Rails configuration object:

    Envy.init use: MyApp::Application.config
    MyApp::Application.config.my_variable # => ...

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
