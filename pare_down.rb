require './app'
require './lib/store'
# maybe store should auto-rotate size?
# yaml should be a log, or limited to previous x days
# data should be persisted daily in a csv
# search would default to the last 2 days
require 'yaml'
require 'time'
class PareDown

  def run
    @start = Time.now
    filename = "./tweets.yaml"
    log "Starting at #{@start}"
    store = Store.new(filename)
    pare_store(store)
  end

  def elapsed_time
    "%.2f minutes" % ((Time.now - @start)/60)
  end

  private

  def pare_store(store)
    log "Opening store"
    store.write do |s|
      pare_by_ids(s.roots, s)
      log "Updating store with changes"
      s.commit
    end
    log "All done"
  end
  def pare_by_ids(ids, store)
    slice_size = 5000
    log "Slicing #{ids.size} ids into groups of #{slice_size}"
    ids.each_slice(slice_size) do |sliced_ids|
      if sliced_ids.size == slice_size
        pare_sliced_ids(sliced_ids, store)
      else
        log "Leaving #{sliced_ids.size} in the file"
      end
    end
  end
  def pare_sliced_ids(sliced_ids, store)
    File.open(slice_filename(sliced_ids), "w") do |file|
      log "Paring range #{sliced_ids.first} to #{sliced_ids.last}"
      yaml = {}
      sliced_ids.each do |id|
        yaml.update(id => store.delete(id))
      end
      file.write YAML::dump(yaml)
    end
  end
  def slice_filename(sliced_ids)
    "tweet_slice_#{sliced_ids.first}.yaml"
  end
  def log(msg)
    STDOUT.puts"[#{elapsed_time}] #{msg}"
  end
end
