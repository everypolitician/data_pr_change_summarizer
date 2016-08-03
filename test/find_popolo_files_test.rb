require 'test_helper'

describe FindPopoloFiles do
  it 'returns files with a matching filename' do
    files = [
      { filename: 'countries.json' },
      { filename: 'data/UK/Commons/ep-popolo-v1.0.json' },
    ]
    popolo_files = FindPopoloFiles.from(files)
    assert_equal [{ filename: 'data/UK/Commons/ep-popolo-v1.0.json' }], popolo_files
  end

  it 'matches any version of the popolo file' do
    files = [
      { filename: 'countries.json' },
      { filename: 'data/UK/Commons/ep-popolo-v2.4.3.json' },
    ]
    popolo_files = FindPopoloFiles.from(files)
    assert_equal [{ filename: 'data/UK/Commons/ep-popolo-v2.4.3.json' }], popolo_files
  end
end
