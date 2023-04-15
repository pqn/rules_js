// Noop to make it easier to search+replace 'eq' type expressions copied from tests
function ok() {}

function escapeTest() {
    const escapeFunction = require('../../node-patches/fs').escapeFunction
    const isEscape = escapeFunction([
        './a/b',
        './a/b/g/1',
        './a/b/g/a/2',
        './a/b/g/a/3',
    ])

    ok(isEscape('./a/b/l', './a/c/boop'))
    ok(isEscape('./a/b', './a/c/boop'))
    ok(isEscape('./a/b', './a'))
    ok(!isEscape('./a/c', './a/c/boop'))
    ok(!isEscape('./a/b/l', './a/b/f'))

    ok(isEscape('./a/b/g/1', './some/path'))
    ok(isEscape('./a/b/g/1/foo', './some/path'))
    ok(isEscape('./a/b/g/h', './some/path'))
    ok(isEscape('./a/b/g/h/i', './some/path'))
    ok(isEscape('./a/b/g/a/2', './some/path'))
    ok(isEscape('./a/b/g/a/2/foo', './some/path'))
    ok(isEscape('./a/b/g/a/3', './some/path'))
    ok(isEscape('./a/b/g/a/3/foo', './some/path'))
    ok(isEscape('./a/b/g/a/h', './some/path'))
    ok(isEscape('./a/b/g/a/h/i', './some/path'))

    ok(isEscape('./a/b/g/1', './a/b'))
    ok(isEscape('./a/b/g/1/foo', './a/b'))
    ok(!isEscape('./a/b/g/h', './a/b'))
    ok(!isEscape('./a/b/g/h/i', './a/b'))
    ok(isEscape('./a/b/g/a/2', './a/b'))
    ok(isEscape('./a/b/g/a/2/foo', './a/b'))
    ok(isEscape('./a/b/g/a/3', './a/b'))
    ok(isEscape('./a/b/g/a/3/foo', './a/b'))
    ok(!isEscape('./a/b/g/a/h', './a/b'))
    ok(!isEscape('./a/b/g/a/h/i', './a/b'))

    ok(isEscape('./a/b/g/1', './a/b/c'))
    ok(isEscape('./a/b/g/1/foo', './a/b/c'))
    ok(!isEscape('./a/b/g/h', './a/b/c'))
    ok(!isEscape('./a/b/g/h/i', './a/b/c'))
    ok(isEscape('./a/b/g/a/2', './a/b/c'))
    ok(isEscape('./a/b/g/a/2/foo', './a/b/c'))
    ok(isEscape('./a/b/g/a/3', './a/b/c'))
    ok(isEscape('./a/b/g/a/3/foo', './a/b/c'))
    ok(!isEscape('./a/b/g/a/h', './a/b/c'))
    ok(!isEscape('./a/b/g/a/h/i', './a/b/c'))

    ok(isEscape('/a/b/l', '/a/c/boop'))
    ok(isEscape('/a/b', '/a/c/boop'))
    ok(isEscape('/a/b', '/a'))
    ok(!isEscape('/a/c', '/a/c/boop'))
    ok(!isEscape('/a/b/l', '/a/b/f'))

    ok(isEscape('/a/b/g/1', '/some/path'))
    ok(isEscape('/a/b/g/1/foo', '/some/path'))
    ok(isEscape('/a/b/g/h', '/some/path'))
    ok(isEscape('/a/b/g/h/i', '/some/path'))
    ok(isEscape('/a/b/g/a/2', '/some/path'))
    ok(isEscape('/a/b/g/a/2/foo', '/some/path'))
    ok(isEscape('/a/b/g/a/3', '/some/path'))
    ok(isEscape('/a/b/g/a/3/foo', '/some/path'))
    ok(isEscape('/a/b/g/a/h', '/some/path'))
    ok(isEscape('/a/b/g/a/h/i', '/some/path'))

    ok(isEscape('/a/b/g/1', '/a/b'))
    ok(isEscape('/a/b/g/1/foo', '/a/b'))
    ok(!isEscape('/a/b/g/h', '/a/b'))
    ok(!isEscape('/a/b/g/h/i', '/a/b'))
    ok(isEscape('/a/b/g/a/2', '/a/b'))
    ok(isEscape('/a/b/g/a/2/foo', '/a/b'))
    ok(isEscape('/a/b/g/a/3', '/a/b'))
    ok(isEscape('/a/b/g/a/3/foo', '/a/b'))
    ok(!isEscape('/a/b/g/a/h', '/a/b'))
    ok(!isEscape('/a/b/g/a/h/i', '/a/b'))

    ok(isEscape('/a/b/g/1', '/a/b/c'))
    ok(isEscape('/a/b/g/1/foo', '/a/b/c'))
    ok(!isEscape('/a/b/g/h', '/a/b/c'))
    ok(!isEscape('/a/b/g/h/i', '/a/b/c'))
    ok(isEscape('/a/b/g/a/2', '/a/b/c'))
    ok(isEscape('/a/b/g/a/2/foo', '/a/b/c'))
    ok(isEscape('/a/b/g/a/3', '/a/b/c'))
    ok(isEscape('/a/b/g/a/3/foo', '/a/b/c'))
    ok(!isEscape('/a/b/g/a/h', '/a/b/c'))
    ok(!isEscape('/a/b/g/a/h/i', '/a/b/c'))
}

// describe('perf', () => it('perf tests', perf_run))

// const patchedFs = Object.assign({}, fs)
// patchedFs.promises = Object.assign({}, fs.promises)
// patcher(patchedFs, [path.join(fixturesDir, 'a')])

// Prefix main 'describe' call with 'exports.default = async () => '
// to make it work with 'perf_run' function below.

async function perf_run() {
    // for (let i=0; i<10000; i++) escapeTest()
    for (let i = 0; i < 1000; i++) await require('./readlink').default()
}

setTimeout(perf_run, 0)
