class ReviewChanges
  attr_reader :popolo_files

  def initialize(popolo_before_after)
    @popolo_files = popolo_before_after.map do |opts|
      ComparePopolo.parse(opts)
    end
  end

  def to_html
    template.result(binding)
  end

  def template
    @template ||= ERB.new(File.read('comment_template.md.erb'))
  end
end
