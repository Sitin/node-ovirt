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

  dumpFileHash = (response, target) ->
    parser = new lib.OVirtResponseParser
      response: loadResponse response
      target: target
    parser._parser.options.validator = null
    parser.parseXML (error, result) ->
      console.log error if error
      inspect result

  dumpHydratedHash = (response, target) ->
    parser = new lib.OVirtResponseParser
      response: loadResponse response
      target: target
    parser.parse (error, result) ->
      console.log error if error
      inspect parser._hydrator
      inspect parser.target

  dumpFileHash 'api', 'api'
#  dumpHydratedHash 'api', 'api'
else
  module.exports = lib