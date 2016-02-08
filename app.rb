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
  Changes = Struct.new(:added, :removed)

  attr_reader :before
  attr_reader :after

  def self.read(before_file, after_file)
    parse(File.read(before_file), File.read(after_file))
  end

  def self.parse(before_string, after_string)
    before = Everypolitician::Popolo.parse(before_string)
    after = Everypolitician::Popolo.parse(after_string)
    new(before, after)
  end

  def initialize(before, after)
    @before = before
    @after = after
  end

  def changed_ids(collection)
    before_ids = before.__send__(collection).map { |item| item.id }
    after_ids = after.__send__(collection).map { |item| item.id }
    Changes.new(after_ids - before_ids, before_ids - after_ids)
  end

  def changed(collection)
    ids = changed_ids(collection)
    Changes.new(ids.added.map { |id| after.persons.find { |p| p.id == id } }, [])
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

  def perform(pull_request_number)
    pull_request = github.pull_request(everypolitician_data_repo, pull_request_number)
    files = github.pull_request_files(everypolitician_data_repo, pull_request_number)
    popolo_files = FindPopoloFiles.from(files).map do |file|
      before = open(file[:raw_url].sub(pull_request[:head][:sha], pull_request[:base][:sha])).read
      after = open(file[:raw_url]).read
      comparer = ComparePopolo.parse(before, after)
      PopoloFile.new(file[:filename], comparer)
    end

    template = ERB.new(File.read('comment_template.md.erb'))
    comment = template.result(binding)

    github.add_comment(everypolitician_data_repo, pull_request_number, comment)
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
