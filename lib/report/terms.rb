class Report
  class Terms < Base
    def terms(events)
      events.select do |event|
        event if event.document[:classification] == 'legislative period'
      end
    end

    def added
      terms(after.events - before.events)
    end

    def removed
      terms(before.events - after.events)
    end
  end
end
