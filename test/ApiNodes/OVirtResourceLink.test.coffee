"use strict"

# Setup chai assertions.
chai = require 'chai'
spies = require 'chai-spies'
chai.use spies
{expect} = chai

# Utilities:
_ = require 'lodash'

{OVirtConnection, ApiNodes} = require '../../lib/'
{OVirtResource, OVirtResourceLink, OVirtApiNode} = ApiNodes


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


  describe "#resolve", ->

    it "should return resource object instance", ->
      link = do getResourceLink
      expect(do link.resolve).to.be.instanceOf OVirtResource

    it "should be binded to an instance", ->
      node = do getResourceLink
      expect(do node.resolve.call).to.be.deep.equal do node.resolve
