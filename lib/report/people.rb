class Report
  class People < Base
    def added
      after.persons - before.persons
    end

    def removed
      before.persons - after.persons
    end
  end
end
