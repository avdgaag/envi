require 'envy/version'
require 'yaml'

module Envy
  FileNotFound       = Class.new(StandardError)
  UnknownEnvironment = Class.new(StandardError)

  ENVY_DEFAULT_CONFIG_FILE = 'config/envars.yml'.freeze
  ENVY_DEFAULT_ENVIRONMENT = 'production'.freeze

  module_function

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

  def parse_envars_from(filename)
    contents = File.readlines(filename).each do |line|
      name, value = line.chomp.split('=', 2)
      ENV[name] = value
    end
  rescue Errno::ENOENT => e
    raise FileNotFound, e
  end

  def set(name, value, options)
    if object = options[:use]
      object.send("#{name.downcase}=", value)
    end
    const_set name, value
    (@_envy_constants ||= []) << name
  end

  def config(options)
    location = options.fetch(:config, ENVY_DEFAULT_CONFIG_FILE)
    env      = options.fetch(:environment, environment)
    YAML.load_file(location).fetch(env) do
      raise UnknownEnvironment, 'No configuration found for environment ' + environment
    end
  rescue Errno::ENOENT => e
    raise FileNotFound, e
  end

  def environment
    ENV['RACK_ENV'] || ENV['RAILS_ENV'] || ENVY_DEFAULT_ENVIRONMENT
  end

  def reset_consts
    (@_envy_constants || []).each do |name|
      remove_const name if const_defined? name
    end
  end
end
