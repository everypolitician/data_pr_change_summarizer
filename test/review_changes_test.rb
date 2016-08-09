require 'test_helper'

describe ReviewChanges do
  let(:before_after) do
    [
      {
        before: {
          persons:       [
            { id: '123', name: 'Bob' },
            { id: '456', name: 'Alice' },
          ],
          organizations: [
            { id: 'abc', name: 'Reds' },
            { id: 'def', name: 'Greens' },
          ],
          events:        [
            {
              classification: 'legislative period',
              id:             'term/52',
              name:           '52nd Parliament of the United Kingdom',
            },
            {
              classification: 'legislative period',
              id:             'term/53',
              name:           '53rd Parliament of the United Kingdom',
            },
          ],
        }.to_json,
        after:  {
          persons:       [
            { id: '123', name: 'Bob' },
            { id: '789', name: 'Carol' },
          ],
          organizations: [
            { id: 'abc', name: 'Reds' },
            { id: 'ghi', name: 'Blues' },
          ],
          events:        [
            {
              classification: 'legislative period',
              id:             'term/53',
              name:           '53rd Parliament of the United Kingdom',
            },
            {
              classification: 'legislative period',
              id:             'term/54',
              name:           '54th Parliament of the United Kingdom',
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
    assert comment.include?('Summary of changes in `foo/bar.json`:')
    assert comment.include?('- `789` - Carol')
    assert comment.include?('- `456` - Alice')
    assert comment.include?('- `def` - Greens')
    assert comment.include?('- `ghi` - Blues')
    assert comment.include?('- `term/54` - 54th Parliament of the United Kingdom')
    assert comment.include?('- `term/52` - 52nd Parliament of the United Kingdom')
  end
end
