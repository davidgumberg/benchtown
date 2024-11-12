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
    base_path = File.expand_path('../../src/_pulls', __dir__)
    Dir.children(base_path)
       .filter_map { |f| File.join(base_path, f) if File.directory?(File.join(base_path, f)) }
       .each do |pr_path|
         Dir.children(pr_path)
            .filter_map { |f| File.join(pr_path, f) if File.directory?(File.join(pr_path, f)) }
            .each { |run_path| gen_run(Dir.new(run_path)) }
       end
  end

  def gen_run(run_dir)
    raise ArgumentError, "gen_run passed a non 'Dir' param" unless run_dir.respond_to?(:path)

    results_json_path = File.expand_path('results.json', run_dir.path)
    results = hash_from_json results_json_path if File.exist?(results_json_path)

    github_json_path = File.expand_path('github.json', run_dir.path)
    github = hash_from_json github_json_path if File.exist?(github_json_path)

    run_vars = {}.merge(results).merge({"github": github})

    add_resource :runs, "#{github["run_id"]}.html" do
      layout :run
      ____ run_vars
    end
  end
end

def dir_from_path(filename, dir)
  Dir.new(File.expand_path(filename, dir))
end

def hash_from_json(path)
  raise ArgumentError, "Path must be a string" unless path.is_a?(String)
  file = File.read(path)
  JSON.parse(file)
rescue JSON::ParserError => e
    puts "Failed to parse JSON: #{e.message}"
rescue Errno::ENOENT => e
    puts "File not found: #{e.message}"
end
