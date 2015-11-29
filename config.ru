require_relative './app'
require 'rack/github_webhooks'
use Rack::GithubWebhooks, secret: ENV['GITHUB_WEBHOOK_SECRET']
run PullRequestReview
