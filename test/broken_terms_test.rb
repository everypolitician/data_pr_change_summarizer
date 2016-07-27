require 'test_helper'

describe 'ComparePopolo' do

  subject do
    ComparePopolo.parse(
      path: 'foo/bar.json',
      before: open('test/fixtures/before.json').read,
      after: open('test/fixtures/after.json').read
    )
  end

  it 'should return a list of broken terms' do
    subject.broken_terms
  end

  it 'should a single broken term' do
  	subject.broken_terms.size.must_equal 1
  end
end

describe ReviewChanges do
  let(:before_after) do
    [
      {
        before: {
          events: [
          	{ classification: 'legislative period', id: 'term/23' }
          ]
        }.to_json,
        after: {
        	events: [
          	{ classification: 'legislative period', id: 'term/23' },
          	{ classification: 'legislative period', id: 'term/dog' },
          	{ classification: 'legislative period', id: 'term/bag' }
          ]
        }.to_json,
        path: 'foo/bar.json'
      }
    ]
  end

  subject { ReviewChanges.new(before_after) }

  it 'should report any broken terms in the comments' do
    comment = subject.to_html
    assert comment.include?('broken:')
  end

  it 'should report any broken terms in the comments' do
    comment = subject.to_html
    assert comment.include?('dog')
    assert comment.include?('bag')
  end
end