"use strict"

# Setup chai assertions.
chai = require 'chai'
spies = require 'chai-spies'
chai.use spies
{expect} = chai

# Utilities:
_ = require 'lodash'

{OVirtApi, OVirtApiNode, OVirtConnection} = require '../lib/'

describe 'OVirtApi', ->
  getApi = (mixin) ->
    mixin = {} unless mixin?
    new OVirtApi _.defaults mixin,
      connection: new OVirtConnection

  it "should be a function", ->
    expect(OVirtApi).to.be.a 'function'

  it "should be inherited from OVirtApiNode", ->
    api = do getApi
    expect(api).to.be.an.instanceOf OVirtApiNode
