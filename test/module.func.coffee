"use strict"


lib = require __dirname + '/../'
Fiber = require 'fibers'
_ = require 'lodash'

fs = require 'fs'
eyes = require 'eyes'
inspect = eyes.inspector maxLength: no

dumpRequestHash = ->
  request = new lib.OVirtApiRequest require '../private.json'
  request.call (error, result) ->
    console.log error if error
    inspect result

loadResponse = (name) ->
  fs.readFileSync "#{__dirname}/responses/#{name}.xml"

dumpHydratedRequest = ->
  fiber = Fiber ->
    connection = new lib.OVirtConnection require '../private.json'
    api =  do connection.connect
    vms = api.vms.findAll name: 'db-vm2'
    vm = vms[0]
    nics = vm.nics.getAll()
    nic = nics[0]
    cluster = nic.vm.cluster

    inspect cluster.$attributes
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

playWithXmlDom = (file = 'api') ->
  xml = loadResponse file

  libxmljs = require 'libxmljs'
  libxmlDoc = libxmljs.parseXml xml

  collections = libxmlDoc.find '//*[not(name()="special_objects")]/link[@href and @rel and not(contains(@rel, "/search"))]'

  for collection in collections
    rel = collection.attr('rel').value()

    searchOption = collection.get "../link[@href and @rel='#{rel}/search']"
    if searchOption?
      collection.attr search: searchOption.remove().attr('href').value()

    specialObjects = collection.find "../special_objects/link[@href and @rel and starts-with(@rel, '#{rel}/')]"
    if specialObjects?.length > 0 then for specialObject in specialObjects
      objectRel = specialObject.attr('rel').value().replace "#{rel}/", ''
      specialObject.attr('rel').value objectRel

      collection.addChild specialObject.remove()

    inspect rel
    console.log collection.toString()

#    inspect entry.attr('rel').value() for entry in libxmlDoc.find '//special_objects/link[@href and @rel]'
#    inspect entry.attr('rel').value() for entry in libxmlDoc.find '//link[@href and @rel and not(contains(@rel, "/search"))]'
#    inspect entry.name() for entry in libxmlDoc.find '/*//*[@href and @id]'



#  dumpFileHash 'api'
#  dumpHydratedHash 'vms.ID'
#  do dumpHydratedRequest
do playWithXmlDom