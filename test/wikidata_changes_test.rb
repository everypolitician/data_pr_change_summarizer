require 'test_helper'

describe ReviewChanges do
  let(:before_after) do
    [
      {
        before: {
          persons: [
            {
              id:          1,
              name:        'Taivo',
              identifiers: [{ identifier: 'Q03785077', scheme: 'wikidata' }],
            },
            {
              id:          2,
              name:        'Douglas',
              identifiers: [{ identifier: 'Q42', scheme: 'wikidata' }],
            },
            {
              id:   3,
              name: 'Fred',
            },
          ],
        }.to_json,
        after:  {
          persons: [
            {
              id:          1,
              name:        'Taivo',
              identifiers: [{ identifier: 'Q3785077', scheme: 'wikidata' }],
            },
            {
              id:   2,
              name: 'Douglas',
            },
            {
              id:          3,
              name:        'Fred',
              identifiers: [{ identifier: 'Q447392', scheme: 'wikidata' }],
            },
          ],
        }.to_json,
        path:   'foo/bar.json',
      },
    ]
  end

  subject { ReviewChanges.new(before_after) }

  it 'renders the comment template' do
    comment = subject.to_html
    assert comment.include?('- `1`: Q03785077 → Q3785077')
    assert comment.include?('- `2`: Q42 → none')
    assert comment.include?('- `3`: none → Q447392')
  end
end
