"use strict"

# Setup chai assertions.
chai = require 'chai'
spies = require 'chai-spies'
chai.use spies
{expect} = chai

# Utilities:
_ = require 'lodash'

{OVirtConnection, ApiNodes} = require '../../lib/'
{OVirtResource, OVirtApiNode} = ApiNodes


describe 'OVirtResource', ->
  getResource = (mixin) ->
    mixin = {} unless mixin?
    new OVirtResource _.defaults mixin,
      connection: new OVirtConnection

  it "should be a function", ->
    expect(OVirtResource).to.be.a 'function'

  it "should be inherited from OVirtApiNode", ->
    api = do getResource
    expect(api).to.be.an.instanceOf OVirtApiNode
