class Report
  class PeopleNames < Base
    def before_names
      @name_hash_pre ||= Hash[before.persons.map { |p| [p.id, p.name] }]
    end

    def after_names
      @name_hash_post ||= Hash[after.persons.map { |p| [p.id, p.name] }]
    end

    def changed
      in_both = before_names.keys & after_names.keys
      in_both.select { |id| !before_names[id].casecmp(after_names[id].downcase).zero? }.map do |id|
        {
          id:  id,
          was: before_names[id],
          now: after_names[id],
        }
      end
    end
  end
end
