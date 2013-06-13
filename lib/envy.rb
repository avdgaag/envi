require 'yaml'

# Envy is a simple module to define environment variable requirements, and to load
# those environment variables into Ruby constants. This is ideal for managing configuration
# settings using environment variables, as one would on [Heroku].
#
# ## Setup
#
# ### The `envars.yml` file
#
# First, define your requirements in a YAML file. By default, Envy will look for
# `./config/envars.yml`. For example:
#
#     ---
#     &defaults:
#       - name: AWS_ACCESS_KEY
#         message: Please provide your Amazon AWS credentials as environment variables.
#       - name: AWS_ACCESS_SECRET
#         message: Please provide your Amazon AWS credentials as environment variables.
#       - name: HASHING_SALT
#     production:
#       <<: *defaults
#     development:
#       <<: *defaults
# {: lang="yaml" }
#
# You can define your required environment variables by name, and also provide
# an optional custom exception message to be used when that variable is not
# set.
#
# ### Initializing Envy
#
# To read the requirements and inspect the current environment variables,
# simply call `Envy.init`. This will raise an exception if requirements are not
# met. When working with Rails apps, you might want to use this is an
# initializer.
#
# ### Providing environment variables in a file
#
# A common pattern is to define custom environment variables in a `.env` file
# in your application's root directory. Other gems, such as [Foreman][] will
# use such a file to augment the environment before running processes. When in
# development mode, Envy can also do this for you. Simply tell it which file to
# use:
#
#     Envy.init parse: '.env'
# {: lang="ruby" }
#
# It is a good idea to not include such a file (which commonly contains
# application secrets) in source control.
#
# ### Extending your Rails application configuration
#
# Envy will expose all the loaded environment variables as constants in the Envy
# module, so you can access them as `Envy::MY_VARIABLE`. You could also opt to extend
# your Rails configuration object:
#
#     Envy.init use: MyApp::Application.config
#     MyApp::Application.config.my_variable # => ...
#
#@author Arjan van der Gaag <arjan@arjanvandergaag.nl>
#
# [Heroku]: http://heroku.com
module Envy
  # Special exception raised when required files could not be found. This is a
  # library-specific wrapper around Errno::ENOENT.
  FileNotFound = Class.new(StandardError)

  # Special exception raised when the currently configured environment name is
  # not present in the configuration file.
  UnknownEnvironment = Class.new(StandardError)

  # @return [String] standard location to look for a configuration YAML file
  ENVY_DEFAULT_CONFIG_FILE = 'config/envars.yml'.freeze

  # @return [String] the default environment to load from the configuration file
  ENVY_DEFAULT_ENVIRONMENT = 'production'.freeze

  # @return [String] Envy gem version in format major.minor.patch
  VERSION = '0.0.1'.freeze

  module_function

  # Define the required environment variables defined in the configuration YAML
  # file (or the `:config` option) as constants on the {Envy} module. Any
  # previously defined constants will be removed.
  #
  # @param [Hash] options
  # @option options [String] :parse path to a file to read extra environment
  #   variables from.
  # @option options [Object] :use an object to set downcased properties on
  # @option options [String] :config path to the configuration file. Defaults
  #   to value of {ENVY_DEFAULT_CONFIG_FILE}
  # @option options [String] :enviroment name of the application environment.
  #   Defaults to {environment}.
  # @raise {NameError} when a required environment variable is not set.
  # @raise {FileNotFound} when files in the `:config` or `:parse` options could
  #   not be found.
  # @raise {UnknownEnvironment} when the current environment is not defined in
  #   the configuration file.
  # @return [Hash] the parsed YAML configuration file
  def init(options = {})
    reset_consts
    parse_envars_from(options[:parse]) if options[:parse]
    config(options).each do |envar|
      name = envar.fetch('name')
      value = ENV.fetch(name) do
        raise NameError, envar.fetch('message', "Required environment variable #{name} is undefined")
      end
      set name, value, options
    end
  end

  # Read and parse a given `filename` and extract environment variables from it.
  #
  # @example
  #   # in .env
  #   FOO=bar
  #
  #   parse_envars_from('.env')
  #   ENV['FOO'] # => 'bar'
  # @raise {FileNotFound} when `filename` is not readable
  def parse_envars_from(filename)
    contents = File.readlines(filename).each do |line|
      name, value = line.chomp.split('=', 2)
      ENV[name] = value
    end
  rescue Errno::ENOENT => e
    raise FileNotFound, e
  end

  # Store a constant by its `name` and `value` by defining it as a constant in
  # the Envy module. Optionally, this will call a setter method on the object
  # in `options[:use]`.
  #
  # @param [String] name of the constant to define
  # @param [String] value of the constant to define
  # @param [Hash] options
  # @option options [Object] :use an object to set downcased properties on
  def set(name, value, options)
    if object = options[:use]
      object.send("#{name.downcase}=", value)
    end
    const_set name, value
    (@_envy_constants ||= []) << name
  end

  # Loads the YAML configuration file and returns the keys under the {environment}.
  #
  # @param [Hash] options
  # @option options [String] :config path to the configuration file. Defaults
  #   to value of {ENVY_DEFAULT_CONFIG_FILE}
  # @option options [String] :enviroment name of the application environment.
  #   Defaults to {environment}.
  # @raise {UnknownEnvironment} when the current environment is not defined in
  #   the configuration file.
  # @see environment
  def config(options)
    location = options.fetch(:config, ENVY_DEFAULT_CONFIG_FILE)
    env      = options.fetch(:environment, environment)
    YAML.load_file(location).fetch(env) do
      raise UnknownEnvironment, 'No configuration found for environment ' + environment
    end
  rescue Errno::ENOENT => e
    raise FileNotFound, e
  end

  # @return [String] the value of RACK_ENV, RAILS_ENV or {ENVY_DEFAULT_ENVIRONMENT}
  def environment
    ENV['RACK_ENV'] || ENV['RAILS_ENV'] || ENVY_DEFAULT_ENVIRONMENT
  end

  # Remove any constants previously defined with {set}.
  def reset_consts
    (@_envy_constants || []).each do |name|
      remove_const name if const_defined? name
    end
  end
end
