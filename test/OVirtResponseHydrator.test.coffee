"use strict"

# Setup chai assertions.
chai = require 'chai'
spies = require 'chai-spies'
chai.use spies
{expect} = chai

# Utilities:
_ = require 'lodash'
fs = require 'fs'

{OVirtResponseHydrator, OVirtApi, OVirtApiNode, OVirtCollection, OVirtResource} = require '../lib/'

loadResponse = (name) ->
  fs.readFileSync "#{__dirname}/responses/#{name}.xml"

describe 'OVirtResponseHydrator', ->
  getHydrator = (target, hash) ->
    target = new OVirtApi unless target?
    new OVirtResponseHydrator target, hash

  it "should be a function", ->
    expect(OVirtResponseHydrator).to.be.a 'function'

  describe "#constructor", ->

    it "should accept target and hash as parameters", ->
      hash = api: []
      target = new OVirtApi
      hydrator = getHydrator target, hash
      expect(hydrator).to.have.property 'hash', hash
      expect(hydrator).to.have.property 'target', target

    it "should restrict target to OVirtApiNode instances", ->
      expect(-> getHydrator {}).
        to.throw "Hydrator's target should be an OVirtApiNode instance"


  describe "getSearchOptionCollectionName", ->

    it "should extract first element of the collection search link 'rel'", ->
      hydrator = do getHydrator
      expect(hydrator.getSearchOptionCollectionName "api/search").to.be.equal "api"

    it "should return udefined for non searchable paths", ->
      hydrator = do getHydrator
      expect(hydrator.getSearchOptionCollectionName "api/").to.be.equal undefined
      expect(hydrator.getSearchOptionCollectionName "api").to.be.equal undefined
      expect(hydrator.getSearchOptionCollectionName "").to.be.equal undefined


