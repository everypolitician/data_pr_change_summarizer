require 'bundler'
Bundler.require

require 'open-uri'
require 'erb'
require 'compare_popolo'

class FindPopoloFiles
  POPOLO_FILE_REGEX = /ep-popolo-v(\d+\.)?(\d+\.)?\d+\.json$/

  def self.from(files)
    files.select { |file| file[:filename].match(POPOLO_FILE_REGEX) }
  end
end

class ReviewChanges
  attr_reader :popolo_files

  def initialize(popolo_before_after)
    @popolo_files = popolo_before_after.map do |opts|
      ComparePopolo.parse(opts)
    end
  end

  def to_html
    template.result(binding)
  end

  def template
    @template ||= ERB.new(File.read('comment_template.md.erb'))
  end
end

class PullRequestReview
  include WebhookHandler

  def perform(pull_request_number)
    pull_request = github.pull_request(everypolitician_data_repo, pull_request_number)
    files = github.pull_request_files(everypolitician_data_repo, pull_request_number)
    popolo_before_after = FindPopoloFiles.from(files).map do |file|
      {
        path:   file[:filename],
        before: open(file[:raw_url].sub(pull_request[:head][:sha], pull_request[:base][:sha])).read,
        after:  open(file[:raw_url]).read,
      }
    end

    begin
      github.add_comment(
        everypolitician_data_repo,
        pull_request_number,
        ReviewChanges.new(popolo_before_after).to_html
      )
    rescue Octokit::UnprocessableEntity
      warn "No changes detected on pull request #{pull_request_number}"
    end
  end

  def handle_webhook
    unless request.env['HTTP_X_EVERYPOLITICIAN_EVENT'] == 'pull_request_opened'
      warn "Unhandled EveryPolitician event: #{request.env['HTTP_X_EVERYPOLITICIAN_EVENT']}"
      return
    end
    request.body.rewind
    payload = JSON.parse(request.body.read)
    self.class.perform_async(payload['pull_request_url'].split('/').last)
  end

  private

  def github
    @github ||= Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end

  def everypolitician_data_repo
    ENV.fetch('EVERYPOLITICIAN_DATA_REPO', 'everypolitician/everypolitician-data')
  end
end
