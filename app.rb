require 'bundler'
Bundler.require

require 'open-uri'
require 'erb'
require 'compare_popolo'
require 'review_changes'
require 'pull_request_review'

class FindPopoloFiles
  POPOLO_FILE_REGEX = /ep-popolo-v(\d+\.)?(\d+\.)?\d+\.json$/

  def self.from(files)
    files.select { |file| file[:filename].match(POPOLO_FILE_REGEX) }
  end
end

