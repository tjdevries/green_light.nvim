local TestRun = R('gl.run_test').TestRun

local run = TestRun:new {
  test_pattern = 'TestIndexer',
  file_pattern = '/home/tj/sourcegraph/lsif-go/internal/indexer/...',
  cwd = '/home/tj/sourcegraph/lsif-go/',
}

run:run()
