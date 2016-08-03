require 'test_helper'

describe ReviewChanges do
  let(:before_after) do
    [
      {
        before: {
          persons:       [
            { id: '123', name: 'Alice' },
            { id: '135', name: 'Bob'   },
            { id: '147', name: 'Carol' },
            { id: '159', name: 'Derek' },
          ],
          organizations: [
            { id: 'abc', name: 'Rouge' },
            { id: 'def', name: 'Green' },
          ],
        }.to_json,
        after:  {
          persons:       [
            { id: '123', name: 'Alice'    },
            { id: '135', name: 'Bobby'    },
            { id: '147', name: 'Caroline' },
            { id: '169', name: 'Derek'    },
          ],
          organizations: [
            { id: 'abc', name: 'Red'   },
            { id: 'def', name: 'Green' },
            { id: 'ghi', name: 'Blue'  },
          ],
        }.to_json,
        path:   'foo/bar.json',
      },
    ]
  end

  subject { ReviewChanges.new(before_after) }

  it 'renders the comment template' do
    comment = subject.to_html
    assert comment.include?('- `135`: Bob → Bobby')
    assert comment.include?('- `147`: Carol → Caroline')
  end
end
