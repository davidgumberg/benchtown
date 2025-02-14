class Runs::Run < Bridgetown::Component
  @@networks = [ 'mainnet-default', 'mainnet-base', 'signet' ]
  #@@graphs = [
  #  'cache_vs_height',
  #  'cache_vs_time,
  #]

  def initialize(run:)
    @run = run
    @networks = @run.data.dig('networks')
    @plots = @run.data.dig('plots')
    @pr_number = @run.data.dig('pr_number')
    @run_id = @run.data.dig('github', 'run_id')
    @run_data_path = "benchcoin/pr-#{@pr_number}/#{@run_id}"
  end
end
