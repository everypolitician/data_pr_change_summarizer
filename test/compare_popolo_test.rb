require 'test_helper'

describe ComparePopolo do
  subject do
    ComparePopolo.parse(
      path:   'foo/bar.json',
      before: open('test/fixtures/before.json').read,
      after:  open('test/fixtures/after.json').read
    )
  end

  it 'has a path' do
    assert_equal 'foo/bar.json', subject.path
  end

  it 'returns the full popolo for added people' do
    assert_equal [Everypolitician::Popolo::Person.new(id: '83af0ada-521a-4043-8b14-49dff73a9389')], subject.people_added
  end

  it 'returns the full popolo for removed people' do
    assert_equal [Everypolitician::Popolo::Person.new(id: '3ec0c09e-462f-4b26-9596-bbcd0683f43e')], subject.people_removed
  end

  it 'returns the full popolo for added organizations' do
    assert_equal [Everypolitician::Popolo::Organization.new(id: '47e60c56-a663-4cad-b8d8-b63309fdd7c4')], subject.organizations_added
  end

  it 'returns the full popolo for removed organizations' do
    assert_equal [Everypolitician::Popolo::Organization.new(id: '88f2ef1f-f686-4496-a41c-98b6bb3ccaa7')], subject.organizations_removed
  end

  it 'should return the full popolo for removed terms' do
    assert_equal [Everypolitician::Popolo::Event.new(classification: 'legislative period',
                                                     id:             'term/52',
                                                     name:           '52nd Parliament of the United Kingdom'),], subject.terms_removed
  end

  it 'should return the full popolo for add terms' do
    assert_equal [Everypolitician::Popolo::Event.new(classification: 'legislative period',
                                                     id:             'term/54',
                                                     name:           '54th Parliament of the United Kingdom'),], subject.terms_added
  end
end
