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
            { classification: 'general election', id: 'Q1000', name: 'Argentine general election, 1922' },
          	{ classification: 'general election', id: 'Q2000', name: 'Argentine general election, 1923' }
          ]
        }.to_json,
        after: {
        	events: [
            { classification: 'general election', id: 'Q1000', name: 'Argentine general election, 1922' },
          	{ classification: 'general election', id: 'Q3000', name: 'Argentine general election, 1924' },
          	{ classification: 'general election', id: 'Q4000', name: 'Argentine general election, 1925' },
          	{ classification: 'general election', id: 'Q5000', name: 'Argentine general election, 1926' }
          ]
        }.to_json,
        path: 'foo/bar.json'
      }
    ]
  end

  subject { ReviewChanges.new(before_after) }

  it 'should report any added elections in the comments' do
    comment = subject.to_html
    comment.must_include('Argentine general election, 1924')
    comment.must_include('Argentine general election, 1925')
    comment.must_include('Argentine general election, 1926')
  end

  it 'should report any removed elections in the comments' do
    comment = subject.to_html
    comment.must_include('Argentine general election, 1923')
  end

  it 'should not report any elections that have not been added/removed' do
    comment = subject.to_html
    comment.wont_include('Argentine general election, 1922')
  end
end