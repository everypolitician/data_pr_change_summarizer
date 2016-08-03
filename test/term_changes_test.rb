describe 'ComparePopolo' do

  subject do
    ComparePopolo.parse(
      path: 'foo/bar.json',
      before: open('test/fixtures/before.json').read,
      after: open('test/fixtures/after.json').read
    )
  end

  it 'should return a list of new terms with expected size' do
    subject.terms.added.size.must_equal 2
  end

  it 'should return a list of removed terms with expected size' do
    subject.terms.removed.size.must_equal 1
  end
end


describe ReviewChanges do
  let(:before_after) do
    [
      {
        before: {
          events: [
            { classification: 'legislative period', id: 'term/101' },
          	{ classification: 'legislative period', id: 'term/23' }
          ]
        }.to_json,
        after: {
        	events: [
          	{ classification: 'legislative period', id: 'term/23' },
          	{ classification: 'legislative period', id: 'term/42' },
          	{ classification: 'legislative period', id: 'term/88' }
          ]
        }.to_json,
        path: 'foo/bar.json'
      }
    ]
  end

  subject { ReviewChanges.new(before_after) }

  it 'should report any added terms in the comments' do
    comment = subject.to_html
    comment.must_include('term/42')
    comment.must_include('term/88')
  end

  it 'should report any removed terms in the comments' do
    comment = subject.to_html
    comment.must_include('term/101')
  end

  it 'should not report any terms that have not been added/removed' do
    comment = subject.to_html
    comment.wont_include('term/23')
  end
end