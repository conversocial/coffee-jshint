path = require('path')
fs = require('fs')

escapeInvalidXmlChars = (str) ->
    return str.replace(/</g, "&lt;")
        .replace(/\>/g, "&gt;")
        .replace(/\"/g, "&quot;")
        .replace(/\'/g, "&apos;")
        .replace(/\&/g, "&amp;")

failureMessage = (error) ->
    return escapeInvalidXmlChars("#{error.line}:#{error.character}: #{error.reason}")



formatErrors = (errors) ->
    numTests = errors.length
    output = []
    output.push("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>")
    output.push("<testsuite name=\"coffeejshint\" errors=\"0\" tests=\"#{numTests}\" failures=\"#{numTests}\">")

    # we need at least one testcase or there will be sadness
    if numTests == 0
        output.push("\t<testcase name=\"coffeejshint\" />")

    for error in errors
        fileName = escapeInvalidXmlChars(error.path)
        message = failureMessage(error)
        output.push("\t<testcase className=\"#{fileName}\" name=\"#{message}\">")
        output.push("\t\t<failure message=\"#{message}\" />")
        output.push("\t</testcase>")

    output.push("</testsuite>")
    return output

module.exports = (destination, errors) ->
    output = formatErrors(errors)
    fs.writeFileSync(destination, output.join("\n"))
