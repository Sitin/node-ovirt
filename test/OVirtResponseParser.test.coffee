"use strict"

# Setup chai assertions.
chai = require 'chai'
spies = require 'chai-spies'
chai.use spies
{expect} = chai

# Utilities:
_ = require 'lodash'
fs = require 'fs'

{OVirtResponseParser, OVirtResponseHydrator, ApiNodes, Mixins} = require '../lib/'
{OVirtApi, OVirtApiNode} = ApiNodes
{ApiNodeTargetOwner} = Mixins

xml2js = require 'xml2js'

loadResponse = (name) ->
  fs.readFileSync "#{__dirname}/responses/#{name}.xml"


describe 'OVirtResponseParser', ->
  getResponseParser = (mixin) ->
    mixin = {} unless mixin?
    new OVirtResponseParser _.defaults mixin,
      response: loadResponse 'api'
      target: 'api'

  it "should be a function", ->
    expect(OVirtResponseParser).to.be.a 'function'


  describe "#constructor", ->

    it "should merge only properties those are already exist in the prototype", ->
      parser = new OVirtResponseParser eggs: 'spam', response: '<vms />', target: 'api'
      expect(parser).to.have.not.property 'eggs'
      expect(parser).to.have.property 'response', '<vms />'
      expect(parser).to.have.property 'target'

    it "should set properties via the setters if exists", ->
      backup = OVirtResponseParser.prototype.setTarget
      spy = OVirtResponseParser.prototype.setTarget = chai.spy backup

      do getResponseParser

      expect(spy).to.be.called.once
      OVirtResponseParser.prototype.setTarget = backup

    it "should set properties directly if their setters is not defined", ->
      Hydrator = ->
      parser = getResponseParser Hydrator: Hydrator
      expect(parser._Hydrator).to.be.equal Hydrator

    it "should instantiate parser", ->
      parser = do getResponseParser
      expect(parser._parser).to.be.an.instanceOf xml2js.Parser

    it "should instantiate hydrator", ->
      parser = do getResponseParser
      expect(parser._hydrator).to.be.an.instanceOf OVirtResponseHydrator

    it "should instantiate hydrator and pass current target to it", ->
      parser = do getResponseParser
      expect(parser._hydrator.target).to.be.equal parser.target

    it "should set 'validator' parser option to #hydrate method", ->
      parser = do getResponseParser
      expect(parser._parserOptions).to.have.property 'validator', parser.hydrate


  describe "#setTarget", ->

    it "should be mixed from Mixins.ApiNodeTargetOwner", ->
      parser = do getResponseParser
      expect(parser.setTarget).to.be.equal ApiNodeTargetOwner.setTarget


  describe "#parse", ->

    it "should call a callback", (done) ->
      parser = do getResponseParser
      expect(parser.target).to.be.instanceOf OVirtApiNode
      parser.parse ->
        do done

    it "should parse XML", (done) ->
      parser = do getResponseParser

      parser.parseXML = chai.spy (callback) ->
        do callback

      parser.parse ->
        expect(parser.parseXML).to.have.been.called.once
        do done

    it "should pass hydrated target to callback", (done) ->
      parser = do getResponseParser
      parser.parseXML = (callback) -> do callback
      spy = (error, result)->
        expect(result).to.be.equal parser.target
        do done
      parser.parse spy


  describe "#parseXML", ->

    it "should call a callback", (done) ->
      parser = do getResponseParser
      parser.parseXML ->
        do done

    it "should not throw an error for successfull parsing", (done) ->
      parser = do getResponseParser
      parser.parseXML (error) ->
        expect(error).to.not.exist
        do done

    it "should pass an error if #response couldn't be parsed", (done) ->
      parser = do getResponseParser
      parser.response = '@#$@#$%@#%'
      parser.parseXML (error, result) ->
        expect(error).to.exist
        do done


  describe "#hydrate", ->

    it "should pass all parameters to #hydrateNodeValue() and return it's result", ->
      parser = do getResponseParser
      params = [1, 2, 3]
      parser.hydrateNodeValue = chai.spy ->
        expect(_.toArray arguments).to.be.deep.equal params
        'result'
      expect(parser.hydrate params...).to.be.equal 'result'
      expect(parser.hydrateNodeValue).to.be.called.once

    it "should be binded to parser instance", ->
      parser = do getResponseParser
      hydrate = parser.hydrate
      parser.hydrateNodeValue = chai.spy ->

      do hydrate

      expect(parser.hydrateNodeValue).to.be.called.once

  describe "#hydrateNodeValue", ->

    it "should call hydrator's #hydrate method with passed parameters " +
      "and return it's result", ->
        parser = do getResponseParser
        params = [1, 2, 3]
        spy = parser._hydrator.hydrate = chai.spy ->
          expect(_.toArray arguments).to.be.deep.equal params
          'result'
        expect(parser.hydrate params...).to.be.equal 'result'
        expect(spy).to.be.called.once
