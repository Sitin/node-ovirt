"use strict"

# Setup chai assertions.
chai = require 'chai'
spies = require 'chai-spies'
chai.use spies
{expect} = chai

# Utilities:
_ = require 'lodash'

{OVirtResourceLink, OVirtApiNode, OVirtConnection} = require '../lib/'


describe 'OVirtResourceLink', ->
  getResourceLink = (mixin) ->
    mixin = {} unless mixin?
    new OVirtResourceLink _.defaults mixin,
      connection: new OVirtConnection

  it "should be a function", ->
    expect(OVirtResourceLink).to.be.a 'function'

  it "should be inherited from OVirtApiNode", ->
    api = do getResourceLink
    expect(api).to.be.an.instanceOf OVirtApiNode
