class Report
  class Elections < Base
    def elections(events)
      events.select do |event|
        event if event.document[:classification] == 'general election'
      end
    end

    def added
      elections(after.events - before.events)
    end

    def removed
      elections(before.events - after.events)
    end
  end
end
