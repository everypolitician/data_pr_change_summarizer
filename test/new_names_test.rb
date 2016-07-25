require 'test_helper'

describe ReviewChanges do
  let(:before_after) do
    [
      {
        before: {
          persons: [
            { id: '1',  name: 'Albert' },
            { id: '10', name: 'Fred', other_names: [ { name: 'Freddy' } ]},
            { id: '11', name: 'Tom', other_names: [ { name: 'Tommy' } ]},
            { id: '12', name: 'Jack' },
            { id: '13', name: 'Kate' },
            { id: '14', name: 'Edward', other_names: [ { name: 'Ed' }, { name: 'Ted' }] },
            { id: '15', name: 'Bob', other_names: [{ name: 'Bobby' }] },
          ],
        }.to_json,
        after: {
          persons: [
            # No changes, no other names
            { id: '1',  name: 'Albert' },
            # No changes, with other names
            { id: '10', name: 'Fred', other_names: [ { name: 'Freddy' } ]},
            # Remove name
            { id: '11', name: 'Tom' },
            # Add name
            { id: '12', name: 'Jack', other_names: [{ name: 'Jackie' }] },
            # Add multiple names
            { id: '13', name: 'Kate', other_names: [ { name: 'Katy' }, { name: 'Katie' }] },
            # Change one name
            { id: '14', name: 'Edward', other_names: [ { name: 'Ed' }, { name: 'Eddie' }] },
            # Swap primary
            { id: '15', name: 'Bobby', other_names: [{ name: 'Bob' }] },
          ],
        }.to_json,
        path: 'foo/bar.json'
      }
    ]
  end

  subject { ReviewChanges.new(before_after) }

  it 'renders the comment template' do
    comment = subject.to_html.split(/^### /).find { |s| s.start_with? 'Additional Name Changes' }
    assert comment.include?('- `11` (Tom): Removed: Tommy.')
    assert comment.include?('- `12` (Jack): Added: Jackie.')
    assert comment.include?('- `13` (Kate): Added: Katy ﹠ Katie.')
    assert comment.include?('- `14` (Edward): Removed: Ted. Added: Eddie.')
    refute comment.include?('- `1`')
    refute comment.include?('- `10`')
    refute comment.include?('- `15`')
  end
end
