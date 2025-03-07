require 'json'

# Builder that generates frontmatter from benchcoin output
class Builders::PullRequestsBuilder < SiteBuilder
  def build
    # According to docs, build is performed pre_read, before any content has
    # been loaded into bridgetown, so we need to connect a post_read hook.
    hook :site, :post_read do
      gen_pull_requests
    end
  end

  def gen_pull_requests
    base_path = File.expand_path('../../src/benchcoin', __dir__)
    folder_children(base_path).each do |pr_path|
      run_paths = folder_children(pr_path)
 
      # get a list of every folder ending in -metadata in the last run
      metadata_folders = Dir.glob(File.join(run_paths.last, "*-metadata"))
      next if metadata_folders == []

      github_json_path = File.join(metadata_folders.first, 'github.json')
      next unless File.exist? github_json_path
      # us only need github metadata from one run, they all same 🎐
      github_metadata = hash_from_json(github_json_path)

      pr_runs = run_paths.map { |run_path| gen_run(run_path) }

      # eliminate empty runs
      next unless pr_runs.compact != []

      pr_title = github_metadata.dig("event", "pull_request", "title")
      pr_num = File.basename(pr_path).match(/\d+/).to_s.to_i
      pr_vars = { "runs": pr_runs.compact }
      # https://www.bridgetownrb.com/docs/plugins/external-apis#the-resource-builder
      add_resource :pulls, "#{pr_num}.html" do
        layout :pull
        title pr_num
        pr_title pr_title
        ___ pr_vars
      end
    end
  end

  # this is the main import function, it should be the central point of knowledge
  # about all things how benchcoin lays out it's results, networks, filenames, what graphs it makes,
  # etc..
  def gen_run(run_path)
    raise ArgumentError, 'Path must be a string' unless run_path.is_a?(String)

    # get hyperfine results.json 
    hyperfine_results_path = File.expand_path('results.json', run_path)
    raise IOError, "Cannot find #{hyperfine_results_path}" unless File.exist? hyperfine_results_path
    hyperfine_results = hash_from_json(hyperfine_results_path)

    run_vars = hyperfine_results

    # get a list of every folder ending in -metadata
    metadata_folders = Dir.glob(File.join(run_path, "*-metadata"))
    # format too old
    return if metadata_folders.empty?
      
    # us only need github metadata from one run, they all same 🎐
    github_json_path = File.join(metadata_folders.first, 'github.json')
    raise IOError, "Cannot find #{github_json_path}" unless File.exist? github_json_path
    github = hash_from_json(github_json_path)


   
    # there is no 'run', there is only 'list of subruns'... 
    # get the 'network' names from the metadata folders
    # yes all of this is ugly -- no there isn't another way :)
    networks = metadata_folders.map do |metadata_path|
      # strip the -metadata prefix to get the network name :)
      File.basename(metadata_path).sub(/-metadata$/, '')
    end

    branches = [ 'base', 'head' ]

    # fixme: this will definitely get us into trouble
    plot_paths = Dir.glob(File.join(run_path, "#{networks.first}-plots", "*.png"))
    plots = plot_paths.map do |plot_path|
      filename = File.basename(plot_path)
      title = filename.sub(/\.png$/, '').sub(/_/, ' ')
      { filename: filename, title: title }
    end

    add_resource :runs, "#{github['run_id']}.html" do
      layout :run
      pull github.dig('event', 'pull_request', 'number').to_s # caution: this really has to be a string in order for bridgetown to be happy and identify the relation
      github github
      networks networks
      branches branches
      plots plots
      # the ___ method merges a hash into the `data` hash available to the 'view' of the resource.
      # https://www.bridgetownrb.com/docs/plugins/external-apis#merging-hashes-directly-into-front-matter
      ___ run_vars
    end

    github['run_id'].to_s
  rescue IOError => e
    warn "IOError during loading: #{e}"
  end
end

def dir_from_path(filename, dir)
  Dir.new(File.expand_path(filename, dir))
end

def hash_from_json(path)
  raise ArgumentError, 'Path must be a string' unless path.is_a?(String)

  file = File.read(path)
  JSON.parse(file)
rescue JSON::ParserError => e
  puts "Failed to parse JSON: #{e.message}"
rescue Errno::ENOENT => e
  puts "File not found: #{e.message}"
end

# IMO, facilities for handling full paths should be in Ruby's Dir
# Returns full paths for the children of a directory that are themselves directories
def folder_children(path)
  Dir.children(path).filter_map { |f| File.join(path, f) if File.directory?(File.join(path, f)) }
end
