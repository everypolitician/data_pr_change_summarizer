require 'bundler'
Bundler.require
Dotenv.load

class PullRequestReview
  include WebhookHandler

  def perform(pull_request_number)
    github.add_comment(
      everypolitician_data_repo,
      pull_request_number,
      Everypolitician::PullRequest::Summary.new(pull_request_number).as_markdown
    )
  rescue PullRequestSummarizer::Summarizer::Error => e
    warn e.message
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
