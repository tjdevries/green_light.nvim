RELOAD "gl"

local TestRun = R("gl.test").TestRun

-- local run = TestRun:new({
-- 	test_pattern = "TestIndexer",
-- 	file_pattern = "/home/tj/sourcegraph/lsif-go/internal/indexer/...",
-- 	cwd = "/home/tj/sourcegraph/lsif-go/",
-- })

local run = TestRun:new {
  file_pattern = "./...",
  test_pattern = "TestIndexer/check_external_nested",
  -- cwd = "./test/green_light/",
}

run:run()
