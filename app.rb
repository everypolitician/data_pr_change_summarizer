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
      before = JSON.parse(open(file[:raw_url]).read)
      after = JSON.parse(open(file[:raw_url].sub(pull_request[:head][:sha], pull_request[:base][:sha])).read)
      collection = 'persons'

      # Find out which record are new or changed
      # This leaves us with things in after that aren't in before
      different = after[collection] - before[collection]
      ids = after[collection].map { |d| d['id'] }

      # Find records which have been deleted
      changes = different.map do |person|
        person_before = before[collection].find { |p| p['id'] == person['id'] }
        person_after = after[collection].find { |p| p['id'] == person['id'] }
        changed_keys = person.keys.find_all do |key|
          person_before[key] != person_after[key]
        end
        [person['id'], Hash[changed_keys.map { |key| [key, person_after[key] - person_before[key]] }]]
      end

      binding.pry
    end
  end

  def handle_webhook
    request.body.rewind
    payload = JSON.parse(request.body.read)
    self.class.perform_async(payload['repository']['full_name'], payload['number'])
  end
end

require 'pry'
pr_review = PullRequestReview.new
pr_review.perform('everypolitician/everypolitician-data', 1663)
