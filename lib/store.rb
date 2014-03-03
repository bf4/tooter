class Store

  def initialize(filename, thread_safe=true)
    @store = storage_adapter.new(filename, thread_safe).store
  end

  def storage_adapter
    Yaml
  end

  def read(&block)
    @store.transaction(true, &block)
  end
  #
  # commit
  # delete
  # fetch(name, default)
  def write(&block)
    @store.transaction(false, &block)
  end

end
require 'yaml/store'
class Yaml
  YAML = ::YAML
  attr_reader :store
  def initialize(filename, thread_safe=true)
    filename << ".yaml" unless filename.end_with?('.yaml')
    @store = YAML::Store.new(filename, thread_safe)
    store.ultra_safe = true
    store
  end
end
require 'pstore'
class Binary
  PStore = ::PStore
  attr_reader :store
  def initialize(filename, thread_safe=true)
    filename << ".pstore" unless filename.end_with?('.pstore')
    @store = PStore.new(filename, thread_safe)
    store.ultra_safe = true
    store
  end
end
