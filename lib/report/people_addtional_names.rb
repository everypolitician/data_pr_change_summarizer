class Report
  class PeopleAdditionalNames < PeopleNames
    def changed
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
  end
end
