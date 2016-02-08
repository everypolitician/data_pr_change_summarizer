require 'test_helper'

describe ComparePopolo do
  subject { ComparePopolo.read('test/fixtures/before.json', 'test/fixtures/after.json') }

  it 'returns the added and removed ids for persons' do
    changed = subject.changed_ids(:persons)
    assert_equal changed.added, ['83af0ada-521a-4043-8b14-49dff73a9389']
    assert_equal changed.removed, ['3ec0c09e-462f-4b26-9596-bbcd0683f43e']
  end

  it 'returns the added and removed ids for organizations' do
    changed = subject.changed_ids(:organizations)
    assert_equal changed.added, ['47e60c56-a663-4cad-b8d8-b63309fdd7c4']
    assert_equal changed.removed, ['88f2ef1f-f686-4496-a41c-98b6bb3ccaa7']
  end

  it 'returns the full popolo for changed persons' do
    changed = subject.changed(:persons)
    assert_equal [Everypolitician::Popolo::Person.new(id: '83af0ada-521a-4043-8b14-49dff73a9389', name: 'Bob')], changed.added
  end
end
