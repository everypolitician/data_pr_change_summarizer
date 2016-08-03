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
    @name_hash_pre ||= Hash[before.persons.map { |p| [p.id, p.name] }]
  end

  def after_names
    @name_hash_post ||= Hash[after.persons.map { |p| [p.id, p.name] }]
  end

  def people_name_changes
    in_both = before_names.keys & after_names.keys
    in_both.select { |id| !before_names[id].casecmp(after_names[id].downcase).zero? }.map do |id|
      {
        id:  id,
        was: before_names[id],
        now: after_names[id],
      }
    end
  end

  def people_additional_name_changes
    all_names = lambda do |p|
      other_names = p.other_names.map { |n| n[:name] } rescue []
      (other_names | [p.name]).to_set
    end
    names_all_pre =  Hash[before.persons.map { |p| [p.id, all_names.call(p)] }]
    names_all_post = Hash[after.persons.map  { |p| [p.id, all_names.call(p)] }]
    in_both = names_all_pre.keys & names_all_post.keys
    in_both.select { |id| names_all_pre[id] != names_all_post[id] }.map do |id|
      {
        id:      id,
        name:    before_names[id],
        removed: (names_all_pre[id] - names_all_post[id]).to_a,
        added:   (names_all_post[id] - names_all_pre[id]).to_a,
      }
    end
  end

  def people_added
    after.persons - before.persons
  end

  def people_removed
    before.persons - after.persons
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

class Report

  class Base
    attr_reader :before, :after

    def initialize(_before, _after)
      @before = _before
      @after  = _after
    end
  end

  class Organizations < Base
    def added
      after.organizations - before.organizations
    end

    def removed
      before.organizations - after.organizations
    end
  end

  class Wikidata < Base
    def changed
      prev = Hash[before.persons.map { |p| [p.id, p.wikidata] }]
      post = Hash[after.persons.map  { |p| [p.id, p.wikidata] }]
      in_both = prev.keys & post.keys
      in_both.select { |id| prev[id] != post[id] }.map do |id|
        {
          id:  id,
          was: prev[id] || 'none',
          now: post[id] || 'none',
        }
      end
    end
  end
end



