class Report
  class Organizations < Base
    def added
      after.organizations - before.organizations
    end

    def removed
      before.organizations - after.organizations
    end
  end
end
