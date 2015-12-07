fs = require 'fs'
CoffeeScript = require 'coffee-script'
CoffeeReactTransform = require 'coffee-react-transform'
_ = require 'underscore'
jshint = require('jshint').JSHINT

defaultOptions = [
  'undef'
  # options to relax for cs
  'eqnull'
  'expr'
  'shadow'
  'sub'
  'multistr'
]
errorsToSkip = [
  "Did you mean to return a conditional instead of an assignment?"
  "Confusing use of '!'."
  "Wrap the /regexp/ literal in parens to disambiguate the slash operator."
  "Creating global 'for' variable. Should be 'for (var"
  "Missing '()' invoking a constructor." # covered by coffeelint rule non_empty_constructor_needs_parens
]

# If log is true, prints out results after processing each file
hintFiles = (paths, config, log) ->
  options = buildTrueObj(
    if config.withDefaults
    then _.union config.options, defaultOptions
    else config.options)
  _.map paths, (path) ->
    try
      source = fs.readFileSync(path)
      source = source.toString()
    catch err
      errors = [createInternalError(path, "Error reading #{path}")]
      if log
          console.log formatErrors path, errors
      return errors

    if config.react
        try
          source = CoffeeReactTransform source
        catch err
          errors = [createInternalError(path, "Error transforming #{path}")]
          if log
            console.log formatErrors path, errors
          return errors
    try
        errors = hint source, options, buildTrueObj config.globals
    catch err
        errors = [createInternalError(path, "Error processing #{path}")]
        if log
            console.log formatErrors path, errors
        return errors

    errors = addPathToErrors(path, errors)

    if log and errors.length > 0
      console.log formatErrors path, errors

    return errors

hint = (coffeeSource, options, globals) ->
  csOptions = sourceMap: true, filename: "doesn't matter"
  {js, v3SourceMap, sourceMap} = CoffeeScript.compile coffeeSource, csOptions
  if jshint js, options, globals
    []
  else if not jshint.errors?
    console.log "jshint didn't pass but returned no errors"
    [createInternalError("jshint didn't pass but returned no errors")]
  else
    _.chain(jshint.errors)
      # Last jshint.errors item could be null if it bailed because too many errors
      .compact()
      # Convert errors to use coffee source locations instead of js locations
      .map (error) ->
        try [line, col] = sourceMap.sourceLocation [error.line - 1, error.character - 1]
        _.extend error,
          line: if line? then line + 1 else '?'
          character: if col? then col + 1 else '?'
      # Get rid of errors that don't apply to coffee very well
      .filter (error) ->
        not _.any errorsToSkip, (to_skip) -> error.reason.indexOf(to_skip) >= 0
      .value()

formatErrors = (path, errors) ->
  "--------------------------------\n" +
  "#{path}\n" +
  _(errors)
    .map (error) ->
      "#{error.line}:#{error.character}: #{error.reason}"
    .join('\n')

buildTrueObj = (keys) ->
  _.object keys, (true for i in [0..keys.length])

createInternalError = (path, errString) ->
    # This creates an error object which looks like a jshint error but is
    # for an internal failure.
    return {
        path: path,
        line: '??',
        character: '??',
        reason: errString
    }

addPathToErrors = (path, errors) ->
    for error in errors
        error.path = path

    return errors

module.exports = hintFiles
