_ = require "underscore"
hintFiles = require("./lib-js/hint")
junitReporter = require("./lib-js/junit_reporter")

{argv, help} = require("optimist")
  .usage('$0 [options] filename.coffee ...')
  .options
    options:
      alias: 'o'
      describe: 'comma separated list of JSHint options to turn on'
    'default-options-off':
      type: 'boolean'
      describe: 'turns off default options'
    globals:
      alias: 'g'
      describe: 'comma separated list of global variable names to permit'
    junit:
      alias: 'j'
      describe: 'location to write junit xml output to'
    react:
      alias: 'r'
      type: 'boolean'
      describe: 'enable jsx transformation step'
    verbose:
      alias: 'v'
      type: 'boolean'
      describe: 'print more detailed output'
    version:
      type: 'boolean'
      describe: 'print the version'
    help:
      alias: 'h'
      type: 'boolean'
      describe: 'print usage info'

switch
  when argv.version then console.log require("./package.json").version
  when argv.help then console.log help()
  else
    splitArgs = (strList) -> strList?.split(',') ? []

    # Filter out non-coffee paths
    {coffee, other} = _(argv._).groupBy (path) ->
      if /.+\.coffee$/.test path then "coffee" else "other"
    if argv.verbose and other?.length > 0
      console.log "Skipping files that don't end in .coffee:\n" + other.join('\n')

    errors = hintFiles(coffee,
      options: splitArgs argv.options
      withDefaults: (not argv['default-options-off'])
      globals: splitArgs argv.globals
      verbose: argv.verbose
      react: argv.react
    , true)

    errors = _.flatten(errors)

    if argv.junit
        junitReporter(argv.junit, errors)

    if errors.length is 0
      process.exit 0
    else
      process.exit 1
