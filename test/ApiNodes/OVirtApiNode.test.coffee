"use strict"

# Setup chai assertions.
chai = require 'chai'
spies = require 'chai-spies'
chai.use spies
{expect} = chai

# Utilities:
_ = require 'lodash'

{OVirtConnection, ApiNodes} = require '../../lib/'
{OVirtAction, OVirtApiNode, OVirtApi, OVirtCollection, OVirtResource} = ApiNodes


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

    describe "Instance properties", ->
      apiNode = do getApiNode

      it "should have #$actions property", ->
        expect(apiNode).to.have.property '$actions'

      it "should have #$attributes property", ->
        expect(apiNode).to.have.property '$attributes'

      it "should have #$collections property", ->
        expect(apiNode).to.have.property '$collections'

      it "should have #$connection property", ->
        expect(apiNode).to.have.property '$connection'

      it "should have #$owner property", ->
        expect(apiNode).to.have.property '$owner'

      it "should have #$properties property", ->
        expect(apiNode).to.have.property '$properties'

      it "should have #$resourceLinks property", ->
        expect(apiNode).to.have.property '$resourceLinks'

    it "should map all #properties to itself", ->
      apiNode = do getApiNode
      for property of apiNode.properties
        expect(apiNode).to.have.own.property property, apiNode.properties[property]