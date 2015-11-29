require 'webhook_handler'
require 'octokit'
require 'open-uri'

class PullRequestReview
  include WebhookHandler

  def perform(repository_full_name, number)
    client = Octokit::Client.new
    pull_request = client.pull_request(repository_full_name, number)
    files = client.pull_request_files(repository_full_name, number)
    ep_popolo = files.find_all { |file| file[:filename].match(/ep-popolo-v1.0\.json$/) }
    ep_popolo.each do |file|
      # Get the JSON and parse it
      before = JSON.parse(open(file[:raw_url].sub(pull_request[:head][:sha], pull_request[:base][:sha])).read)
      after = JSON.parse(open(file[:raw_url]).read)
      stats = {}
      %w[persons organizations].each do |collection|
        before_map = Hash[before[collection].map { |item| [item['id'], item] }]
        after_map = Hash[after[collection].map { |item| [item['id'], item] }]
        before_ids = before[collection].map { |item| item['id'] }
        after_ids = after[collection].map { |item| item['id'] }
        stats[collection] = {
          added: (after_ids - before_ids).map { |id| after_map[id] },
          removed: (before_ids - after_ids).map { |id| before_map[id] }
        }
      end
      j stats
    end
  end

  def handle_webhook
    return unless request.env['HTTP_X_GITHUB_EVENT'] == 'pull_request'
    request.body.rewind
    payload = JSON.parse(request.body.read)
    return unless %w(opened synchronize).include?(payload['action'])
    self.class.perform_async(payload['repository']['full_name'], payload['number'])
  end
end
