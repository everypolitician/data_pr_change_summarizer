require 'bundler'
Bundler.require

require 'open-uri'
require 'erb'

class FindPopoloFiles
  POPOLO_FILE_REGEX = /ep-popolo-v(\d+\.)?(\d+\.)?\d+\.json$/

  def self.from(files)
    files.find_all { |file| file[:filename].match(POPOLO_FILE_REGEX) }
  end
end

class ComparePopolo
  attr_reader :before
  attr_reader :after
  attr_reader :path

  def self.parse(options)
    before = Everypolitician::Popolo.parse(options[:before])
    after = Everypolitician::Popolo.parse(options[:after])
    new(before: before, after: after, path: options[:path])
  end

  def initialize(options)
    @before = options[:before]
    @after = options[:after]
    @path = options[:path]
  end

  def people_added
    after.persons - before.persons
  end

  def people_removed
    before.persons - after.persons
  end

  def organizations_added
    after.organizations - before.organizations
  end

  def organizations_removed
    before.organizations - after.organizations
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
        path: file[:filename],
        before: open(file[:raw_url].sub(pull_request[:head][:sha], pull_request[:base][:sha])).read,
        after: open(file[:raw_url]).read
      }
    end

    changes_summary = ReviewChanges.new(popolo_before_after).to_html
    if changes_summary.empty?
      warn "No changes detected in #{pull_request_number} popolo"
      return
    end
    github.add_comment(
      everypolitician_data_repo,
      pull_request_number,
      changes_summary
    )
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
