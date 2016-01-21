require 'webhook_handler'
require 'octokit'
require 'open-uri'
require 'erb'

class FindPopoloFiles
  def self.from(files)
    files.find_all { |file| file[:filename].match(/ep-popolo-v1.0\.json$/) }
  end
end

class ComparePopolo
  Changes = Struct.new(:added, :removed)

  attr_reader :before
  attr_reader :after

  def self.read(before_file, after_file)
    parse(File.read(before_file), File.read(after_file))
  end

  def self.parse(before_string, after_string)
    before = JSON.parse(before_string, symbolize_names: true)
    after = JSON.parse(after_string, symbolize_names: true)
    new(before, after)
  end

  def initialize(before, after)
    @before = before
    @after = after
  end

  def changed_ids(collection)
    before_ids = before[collection.to_sym].map { |item| item[:id] }
    after_ids = after[collection.to_sym].map { |item| item[:id] }
    Changes.new(after_ids - before_ids, before_ids - after_ids)
  end
end

class PopoloFile
  attr_reader :path
  attr_reader :comparer

  def initialize(path, comparer)
    @path = path
    @comparer = comparer
  end

  def people
    comparer.changed_ids(:persons)
  end

  def organizations
    comparer.changed_ids(:organizations)
  end
end

class PullRequestReview
  include WebhookHandler

  def perform(repository_full_name, number)
    pull_request = github.pull_request(repository_full_name, number)
    files = github.pull_request_files(repository_full_name, number)
    popolo_files = FindPopoloFiles.from(files).map do |file|
      before = open(file[:raw_url].sub(pull_request[:head][:sha], pull_request[:base][:sha])).read
      after = open(file[:raw_url]).read
      comparer = ComparePopolo.parse(before, after)
      PopoloFile.new(file[:filename], comparer)
    end

    template = ERB.new(File.read('comment_template.md.erb'))
    comment = template.result(binding)

    github.add_comment(repository_full_name, number, comment)
  end

  def handle_webhook
    return unless request.env['HTTP_X_GITHUB_EVENT'] == 'pull_request'
    request.body.rewind
    payload = JSON.parse(request.body.read)
    return unless payload['repository']['full_name'] == everypolitician_data_repo
    return unless %w(opened synchronize).include?(payload['action'])
    self.class.perform_async(payload['repository']['full_name'], payload['number'])
  end

  private

  def github
    @github ||= Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end

  def everypolitician_data_repo
    ENV.fetch('EVERYPOLITICIAN_DATA_REPO', 'everypolitician/everypolitician-data')
  end
end
