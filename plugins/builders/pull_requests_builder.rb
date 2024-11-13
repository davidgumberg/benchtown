require 'json'

# Builder that generates frontmatter from benchcoin output
class Builders::PullRequestsBuilder < SiteBuilder
  def build
    # According to docs, build is performed pre_read, so we need to connect
    # a post_read hook.
    hook :site, :post_read do
      gen_pull_requests
    end
  end

  def gen_pull_requests
    base_path = File.expand_path('../../src/benchcoin', __dir__)
    folder_children(base_path).each do |pr_path|
      pr_runs = folder_children(pr_path).map { |run_path| gen_run(run_path) }

      # eliminate empty runs
      next unless pr_runs.compact != []

      pr_num = File.basename(pr_path).match(/\d+/).to_s.to_i
      pr_vars = { "runs": pr_runs.compact }
      puts "#{pr_runs.compact} belong to #{pr_num}"
      add_resource :pulls, "#{pr_num}.html" do
        layout :pull
        title pr_num
        ___ pr_vars
      end
    end
  end

  def gen_run(run_path)
    raise ArgumentError, 'Path must be a string' unless run_path.is_a?(String)

    results_json_path = File.expand_path('results.json', run_path)
    return unless File.exist?(results_json_path)

    results = hash_from_json results_json_path if File.exist?(results_json_path)

    github_json_path = File.expand_path('mainnet-metadata/github.json', run_path)
    return unless File.exist?(github_json_path)

    github = hash_from_json github_json_path if File.exist?(github_json_path)

    # REMOVEME: Guard against the old format
    return unless results['results'][0].key?('network')

    run_vars = results.merge({ 'github': github, 'pull': github.dig('event', 'pull_request', 'number').to_s })

    add_resource :runs, "#{github['run_id']}.html" do
      layout :run
      ___ run_vars
    end

    "github['run_id']"
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
