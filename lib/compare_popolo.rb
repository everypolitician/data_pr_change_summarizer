require_all 'lib/report'

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

  def people_name_changes
    Report::PeopleNames.new(before, after).changed
  end

  def people_additional_name_changes
    Report::PeopleAdditionalNames.new(before, after).changed
  end

  def people_added
    Report::People.new(before, after).added
  end

  def people_removed
    Report::People.new(before, after).removed
  end

  def wikidata_links_changed
    Report::Wikidata.new(before, after).changed
  end

  def organizations_added
    Report::Organizations.new(before, after).added
  end

  def organizations_removed
    Report::Organizations.new(before, after).removed
  end
end
