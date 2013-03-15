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

    it "should perform a request to oVirt API", ->
      link = do getResourceLink
      link.$connection = performRequest: spy = chai.spy ->
      do link.resolve
      expect(spy).to.have.been.called.once

    it "should be binded to an instance", ->
      link = do getResourceLink
      link.$connection = performRequest: spy = chai.spy ->
      do link.resolve.call
      expect(spy).to.have.been.called.once
