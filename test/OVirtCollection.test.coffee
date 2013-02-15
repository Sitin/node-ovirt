"use strict"

# Setup chai assertions.
chai = require 'chai'
spies = require 'chai-spies'
chai.use spies
{expect} = chai

# Utilities:
_ = require 'lodash'

{OVirtCollection, OVirtApiNode, OVirtConnection} = require '../lib/'


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
