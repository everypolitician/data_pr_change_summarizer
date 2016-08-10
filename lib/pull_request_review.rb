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
    rescue Octokit::UnprocessableEntity => e
      warn "Unable to review pull request #{pull_request_number}: #{e.message}"
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
