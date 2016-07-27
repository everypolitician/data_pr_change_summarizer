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

  def before_names
    @name_hash_pre ||= Hash[ before.persons.map { |p| [p.id, p.name] } ]
  end

  def after_names
    @name_hash_post ||= Hash[ after.persons.map { |p| [p.id, p.name] } ]
  end

  def people_name_changes
    in_both = before_names.keys & after_names.keys
    in_both.select { |id| before_names[id].downcase != after_names[id].downcase }.map { |id|
      {
        id: id,
        was: before_names[id],
        now: after_names[id],
      }
    }
  end

  def people_additional_name_changes
    all_names = ->(p) { 
      other_names = p.other_names.map { |n| n[:name] } rescue []
      (other_names | [ p.name ]).to_set
    }
    names_all_pre =  Hash[ before.persons.map { |p| [p.id, all_names.(p)] } ]
    names_all_post = Hash[ after.persons.map  { |p| [p.id, all_names.(p)] } ]
    in_both = names_all_pre.keys & names_all_post.keys
    in_both.select { |id| names_all_pre[id] != names_all_post[id] }.map { |id|
      {
        id: id,
        name: before_names[id],
        removed: (names_all_pre[id] - names_all_post[id]).to_a,
        added:   (names_all_post[id] - names_all_pre[id]).to_a,
      }
    }
  end

  def people_added
    after.persons - before.persons
  end

  def people_removed
    before.persons - after.persons
  end

  def wikidata_links_changed
    prev = Hash[before.persons.map { |p| [p.id, p.wikidata] }]
    post = Hash[after.persons.map  { |p| [p.id, p.wikidata] }]
    in_both = prev.keys & post.keys
    in_both.select { |id| prev[id] != post[id] }.map do |id|
      { 
        id: id,
        was: prev[id] || 'none',
        now: post[id] || 'none',
      }
    end
  end

  def organizations_added
    after.organizations - before.organizations
  end

  def organizations_removed
    before.organizations - after.organizations
  end

  def terms_added
    terms_after - terms_before
  end

  def terms_removed
    terms_before - terms_after
  end

  def terms_before
    terms = before.events.select { |event| event[:classification] == "legislative period" }
    terms.map { |t| t[:id] }
  end

  def terms_after
    terms = after.events.select { |event| event[:classification] == "legislative period" }
    terms.map { |t| t[:id] }
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

    begin
      github.add_comment(
        everypolitician_data_repo,
        pull_request_number,
        ReviewChanges.new(popolo_before_after).to_html
      )
    rescue Octokit::UnprocessableEntity => e
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
