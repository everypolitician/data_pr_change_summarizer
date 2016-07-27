require 'test_helper'

describe 'BrokenTerms' do

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

  it 'should 1' do
  	subject.broken_terms.size.must_equal 1
  end
end
