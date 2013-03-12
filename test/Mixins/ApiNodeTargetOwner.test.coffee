"use strict"

# Setup chai assertions.
chai = require 'chai'
spies = require 'chai-spies'
chai.use spies
{expect} = chai

# Utilities:
_ = require 'lodash'
{CoffeeMix} = require 'coffee-mix'

{ApiNodes, Mixins} = require '../../lib/'
{OVirtApi, OVirtApiNode} = ApiNodes
{ApiNodeTargetOwner} = Mixins


describe 'ApiNodeTargetOwner', ->

  describe "#setTarget", ->

    it "should throw an error if target couldn't be converted" +
      "to OVirtApiNode", ->
        class MixinAcceptor extends CoffeeMix
          @include ApiNodeTargetOwner

        obj = new MixinAcceptor
        expect(-> obj.setTarget "something wrong")
          .to.throw TypeError, "MixinAcceptor requires OVirtApiNode as a target"

    it "should try to construct target if function specified", ->
      spy = chai.spy OVirtApiNode
      expect(ApiNodeTargetOwner.setTarget spy)
        .to.be.an.instanceOf OVirtApiNode
      expect(spy).to.be.called.once

    it "should treat string as a target type", ->
      expect(ApiNodeTargetOwner.setTarget 'api')
        .to.be.instanceOf OVirtApi