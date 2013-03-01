"use strict"


lib = require __dirname + '/lib/'


if not module.parent
  fs = require 'fs'
  eyes = require 'eyes'
  inspect = eyes.inspector maxLength: no

  dumpRequestHash = ->
    request = new lib.OVirtApiRequest require './private.json'
    request.call (error, result) ->
      console.log error if error
      inspect result

  loadResponse = (name) ->
    fs.readFileSync "#{__dirname}/test/responses/#{name}.xml"

  dumpHydratedRequest = (options = null, target = 'api') ->
    request = new lib.OVirtApiRequest require './private.json'
    request.call options, (error, xml) ->
      console.log error if error
      console.log xml unless error

      parser = new lib.OVirtResponseParser
        response: xml
        target: target

      parser.parse (error, node) ->
        console.log error if error
        inspect node unless error

  dumpFileHash = (response, target = 'api') ->
    parser = new lib.OVirtResponseParser
      response: loadResponse response
      target: target
    parser._parser.options.validator = null
    parser.parseXML (error, result) ->
      console.log error if error
      inspect result

  dumpHydratedHash = (response, target = 'api') ->
    parser = new lib.OVirtResponseParser
      response: loadResponse response
      target: target
    parser.parse (error, result) ->
      console.log error if error
      inspect parser._hydrator
      inspect parser.target

#  dumpFileHash 'api'
  dumpHydratedHash 'api'
#  do dumpHydratedRequest
else
  module.exports = lib