"use strict"

# Setup chai assertions.
chai = require 'chai'
spies = require 'chai-spies'
chai.use spies
{expect} = chai

# Utilities:
_ = require 'lodash'

disposer = require '../index'
lib = require '../lib/'

describe 'Node.js oVirt driver as a module', ->

  it "should export lib contents", ->
    expect(disposer).to.be.deep.equal lib