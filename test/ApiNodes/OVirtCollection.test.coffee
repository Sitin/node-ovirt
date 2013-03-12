"use strict"

# Setup chai assertions.
chai = require 'chai'
spies = require 'chai-spies'
chai.use spies
{expect} = chai

# Utilities:
_ = require 'lodash'

{OVirtConnection, ApiNodes} = require '../../lib/'
{OVirtCollection, OVirtApiNode} = ApiNodes


describe 'OVirtCollection', ->
  getCollection = (mixin) ->
    mixin = {} unless mixin?
    new OVirtCollection _.defaults mixin,
      connection: new OVirtConnection

  it "should be a function", ->
    expect(OVirtCollection).to.be.a 'function'

  it "should be inherited from OVirtApiNode", ->
    api = do getCollection
    expect(api).to.be.an.instanceOf OVirtApiNode


  describe "#constructor", ->

    it "should set isSearchable to false", ->
      collection = do getCollection
      expect(collection.isSearchable).to.be.false

    it "should set search options to empty hash", ->
      collection = do getCollection
      expect(collection.searchOptions).to.be.deep.equal {}

    it "should set special objects to empty hash", ->
      collection = do getCollection
      expect(collection.specialObjects).to.be.deep.equal {}
