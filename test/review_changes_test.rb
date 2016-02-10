require 'test_helper'

describe ReviewChanges do
  let(:before_after) do
    [
      {
        before: {
          persons: [
            { id: '123', name: 'Bob' },
            { id: '456', name: 'Alice' }
          ],
          organizations: [
            { id: 'abc', name: 'Reds' },
            { id: 'def', name: 'Greens' }
          ]
        }.to_json,
        after: {
          persons: [
            { id: '123', name: 'Bob' },
            { id: '789', name: 'Carol' }
          ],
          organizations: [
            { id: 'abc', name: 'Reds' },
            { id: 'ghi', name: 'Blues' }
          ]
        }.to_json,
        path: 'foo/bar.json'
      }
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
  end
end
