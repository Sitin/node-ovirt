"use strict"


lib = require __dirname + '/lib/'
Fiber = require 'fibers'
_ = require 'lodash'


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

  dumpHydratedRequest = ->
    fiber = Fiber ->
      connection = new lib.OVirtConnection require './private.json'
      api =  do connection.connect
      vms = api.vms.findAll name: 'db-vm2'
      nics = vms[0].nics.getAll()
      statistics = nics[0].statistics.getAll()

      inspect statistics
    do fiber.run

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
#  dumpHydratedHash 'vms.ID'
  do dumpHydratedRequest
else
  module.exports = lib