"use strict"

# Setup chai assertions.
chai = require 'chai'
spies = require 'chai-spies'
chai.use spies
{expect} = chai

# Utilities:
_ = require 'lodash'

{OVirtApiRequest} = require '../lib/'


describe 'OVirtApiRequest', ->

  it "should be a function", ->
    expect(OVirtApiRequest).to.be.a 'function'

  it "should merge only properties those are already exist in the prototype", ->
    request = new OVirtApiRequest eggs: 'spam', method: 'post'
    expect(request).to.have.not.property 'eggs'
    expect(request).to.have.property 'method', 'post'