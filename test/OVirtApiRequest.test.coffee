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
    request = new OVirtApiRequest eggs: 'spam', protocol: 'http'
    expect(request).to.have.not.property 'eggs'
    expect(request).to.have.property 'protocol', 'http'

  request = new OVirtApiRequest
    host: "example.com"
    username: 'username'
    password: 'password'

  describe "#getRequestUri", ->

    it 'should put collection name as a second url element if specified', ->
      url = request.getRequestUri collection: name: 'collection'
      #expect(url).to.match /^api\/collection/

    it 'should treat collection property value as a collection name if it is a string', ->
      url = request.getRequestUri {}

    describe 'result value (URI)', ->
      it "should start with API root URI", ->
        url = request.getRequestUri {}
        expect(url).to.match /^api/