class FindPopoloFiles
  POPOLO_FILE_REGEX = /ep-popolo-v(\d+\.)?(\d+\.)?\d+\.json$/

  def self.from(files)
    files.select { |file| file[:filename].match(POPOLO_FILE_REGEX) }
  end
end
