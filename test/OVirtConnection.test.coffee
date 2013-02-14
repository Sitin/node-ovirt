"use strict"

# Setup chai assertions.
chai = require 'chai'
spies = require 'chai-spies'
chai.use spies
{expect} = chai

# Utilities:
_ = require 'lodash'

{OVirtConnection, OVirtApi} = require '../lib/'

describe 'OVirtConnection', ->

  getConnection = (mixin) ->
    mixin = {} unless mixin?
    new OVirtConnection _.defaults mixin,
      host: "example.com"
      username: 'username'
      password: 'password'

  it "should be a function", ->
    expect(OVirtConnection).to.be.a 'function'

  it "should incapsulate connection properties", ->
    connection = do getConnection
    expect(connection).to.have.property property for property in [
      'protocol', 'host', 'uri', 'username', 'password'
    ]

  describe "#constructor", ->

    it "should merge only properties those are already exist in the prototype", ->
      connection = new OVirtConnection eggs: 'spam', protocol: 'http'
      expect(connection).to.have.not.property 'eggs'
      expect(connection).to.have.property 'protocol', 'http'

  describe "#api", ->
    it "should be an API root resource", ->
      connection = do getConnection
      expect(connection.api).to.be.an.instanceOf OVirtApi

    it "should be lazy", ->
      spy = chai.spy ->
      connection = getConnection OVirtApi: spy
      expect(spy).to.have.not.been.called
      connection.api
      expect(spy).to.have.been.called.once

    it "should instantiate API root resource only if it not existed", ->
      spy = chai.spy ->
      connection = getConnection OVirtApi: spy
      connection.api
      connection.api
      expect(spy).to.have.been.called.once