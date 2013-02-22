"use strict"

# Setup chai assertions.
chai = require 'chai'
spies = require 'chai-spies'
chai.use spies
{expect} = chai

# Utilities:
_ = require 'lodash'

config = require '../lib/config'

describe 'Library config', ->

  it "should be an object", ->
    expect(config).to.be.an.object

  it "should have parser configuration", ->
    expect(config).to.have.property('parser').to.be.an.object

  it "should have API configuration", ->
    expect(config).to.have.property('api').to.be.an.object