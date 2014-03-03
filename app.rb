# Usage
# app = App.new(:rest)
# App.run
# app.print
# App.stream
require 'dotenv'
Dotenv.load
require 'pathname'
class App
  @root = Pathname File.expand_path('..', __FILE__)
  lib_path = @root.join('lib').to_s
  $LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)
  require 'client'

  def self.root
    @root
  end

  def initialize(client_type)
    @client = Client.new(client_type)
  end

  def self.run
    new(:rest).run
  end

  def self.stream
    new(:stream)
  end

  def print
    new(:rest).print
  end

  def run
    @client.run
  end
  def stream
    @client.stream
  end
  def print
    @client.print
  end

end
