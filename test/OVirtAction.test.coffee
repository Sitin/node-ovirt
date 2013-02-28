"use strict"

# Setup chai assertions.
chai = require 'chai'
spies = require 'chai-spies'
chai.use spies
{expect} = chai

# Utilities:
_ = require 'lodash'

{OVirtAction, OVirtApiNode, OVirtConnection} = require '../lib/'


describe 'OVirtAction', ->
  getAction = (mixin) ->
    mixin = {} unless mixin?
    new OVirtAction _.defaults mixin,
      connection: new OVirtConnection

  it "should be a function", ->
    expect(OVirtAction).to.be.a 'function'

  it "should be inherited from OVirtApiNode", ->
    api = do getAction
    expect(api).to.be.an.instanceOf OVirtApiNode
