class App::Report

  def initialize(store)
    @store = store
  end

  def print
    @store.read do |store|
      store.roots.each do |key|
        tweet = store[key]
        puts
        puts %w(full_text user created_at id).map(&:intern).
          map{|attr| tweet[attr] }.
          join("\n\t")
        puts
      end
    end
  end
end
