"use strict"

# Setup chai assertions.
chai = require 'chai'
spies = require 'chai-spies'
chai.use spies
{expect} = chai

# Utilities:
_ = require 'lodash'

{OVirtAction, OVirtApiNode, OVirtApi, OVirtCollection, OVirtConnection, OVirtResource} = require '../lib/'


describe 'OVirtApiNode', ->
  getApiNode = (mixin) ->
    mixin = {} unless mixin?
    new OVirtApiNode _.defaults mixin,
      connection: new OVirtConnection

  it "should be a function", ->
    expect(OVirtApiNode).to.be.a 'function'

  it "should have static hash to save their children types", ->
    expect(OVirtApiNode).to.have.property 'API_NODE_TYPES'


  describe ".API_NODE_TYPES", ->
    it "should have links to api, resource and collection constructors", ->
      API_NODE_TYPES = OVirtApiNode.API_NODE_TYPES
      expect(API_NODE_TYPES).to.have.property 'node', OVirtApiNode
      expect(API_NODE_TYPES).to.have.property 'api', OVirtApi
      expect(API_NODE_TYPES).to.have.property 'collection', OVirtCollection
      expect(API_NODE_TYPES).to.have.property 'resource', OVirtResource
      expect(API_NODE_TYPES).to.have.property 'action', OVirtAction

    it "should have .collections property", ->
      apiNode = do getApiNode
      expect(apiNode).to.have.property 'collections'

    it "should have .properties property", ->
      apiNode = do getApiNode
      expect(apiNode).to.have.property 'properties'

    it "should map all .properties to itself", ->
      apiNode = do getApiNode
      for property of apiNode.properties
        expect(apiNode).to.have.own.property property, apiNode.properties[property]