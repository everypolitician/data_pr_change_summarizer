describe 'ComparePopolo' do

  subject do
    ComparePopolo.parse(
      path: 'foo/bar.json',
      before: open('test/fixtures/before.json').read,
      after: open('test/fixtures/after.json').read
    )
  end

  it 'should return a list of new elections with expected size' do
    subject.elections.added.size.must_equal 2
  end

  it 'should return a list of removed elections with expected size' do
    subject.elections.removed.size.must_equal 1
  end

end


describe ReviewChanges do
  let(:before_after) do
    [
      {
        before: {
          events: [
            { classification: 'general election', id: 'one', name: 'election one' },
          	{ classification: 'general election', id: 'two', name: 'election two' }
          ]
        }.to_json,
        after: {
        	events: [
            { classification: 'general election', id: 'one', name: 'election one' },
          	{ classification: 'general election', id: 'three', name: 'election three' },
          	{ classification: 'general election', id: 'four', name: 'election four' },
          	{ classification: 'general election', id: 'five', name: 'election five' }
          ]
        }.to_json,
        path: 'foo/bar.json'
      }
    ]
  end

  subject { ReviewChanges.new(before_after) }

  it 'should report any added elections in the comments' do
    comment = subject.to_html
    comment.must_include('election three')
    comment.must_include('election four')
    comment.must_include('election five')
  end

  it 'should report any removed elections in the comments' do
    comment = subject.to_html
    comment.must_include('election two')
  end

  it 'should not report any elections that have not been added/removed' do
    comment = subject.to_html
    comment.wont_include('election one')
  end
end