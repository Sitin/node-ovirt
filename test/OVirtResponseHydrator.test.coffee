"use strict"

# Setup chai assertions.
chai = require 'chai'
spies = require 'chai-spies'
chai.use spies
{expect} = chai

# Utilities:
_ = require 'lodash'
fs = require 'fs'

{OVirtResponseHydrator, OVirtApi, OVirtApiNode, OVirtCollection, OVirtResource} = require '../lib/'

loadResponse = (name) ->
  fs.readFileSync "#{__dirname}/responses/#{name}.xml"

describe 'OVirtResponseHydrator', ->

  it "should be a function", ->
    expect(OVirtResponseHydrator).to.be.a 'function'

  describe "#constructor", ->


