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
    assert comment.include?('term/42')
    assert comment.include?('term/88')
  end

  it 'should report any removed terms in the comments' do
    comment = subject.to_html
    assert comment.include?('term/101')
  end
end