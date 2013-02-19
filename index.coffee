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

  dumpFileHash = ->
    parser = new lib.OVirtResponseParser
      response: loadResponse 'api'
      target: 'api'
    parser.parseXML (error, result) ->
      console.log error if error
      inspect result

  dumpHydratedHash = ->
    parser = new lib.OVirtResponseParser
      response: loadResponse 'api'
      target: 'collection'
    parser.parse (error, result) ->
      console.log error if error
      inspect parser.target

  do dumpFileHash
  do dumpHydratedHash
else
  module.exports = lib