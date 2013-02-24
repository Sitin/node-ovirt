"use strict"

# Setup chai assertions.
chai = require 'chai'
spies = require 'chai-spies'
chai.use spies
{expect} = chai

# Utilities:
_ = require 'lodash'
fs = require 'fs'

{OVirtResponseParser, OVirtResponseHydrator, OVirtApi, OVirtApiNode} = require '../lib/'

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


  describe "#setTarget", ->

    it "should throw an error if target couldn't be converted" +
      "to OVirtApiNode", ->
        parser = do getResponseParser
        expect(-> parser.setTarget "something wrong")
          .to.throw TypeError, "OVirtResponseParser requires OVirtApiNode as a target"

    it "should try to construct target if function specified", ->
      parser = do getResponseParser
      spy = chai.spy OVirtApiNode
      expect(parser.setTarget spy).to.be.an.instanceOf OVirtApiNode
      expect(spy).to.be.called.once

    it "should treat string as a target type", ->
      parser = do getResponseParser
      expect(parser.setTarget 'api').to.be.instanceOf OVirtApi


  describe "#parse", ->

    it "should call a callback", (done) ->
      parser = do getResponseParser
      expect(parser.target).to.be.instanceOf OVirtApiNode
      parser.parse ->
        do done

    it "should parse XML and then export parse results", (done) ->
      parser = do getResponseParser

      parser.parseXML = chai.spy (callback) ->
        # XML spy should check that it was called before the export spy.
        expect(parser._exportParseResults).have.not.been.called
        do callback
      parser._exportParseResults = chai.spy ->
        # Export spy should check that it called after the export spy.
        expect(parser.parseXML).have.been.called.once

      parser.parse ->
        expect(parser._exportParseResults).have.been.called.once
        do done

    it "shouldn't invoke #_exportParseResults if parse failed", (done) ->
      parser = do getResponseParser
      parser.parseXML = (callback) ->
        callback "Error!"
      spy = parser._exportParseResults = chai.spy ->
      parser.parse ->
        expect(spy).to.have.not.been.called
        do done


  describe "#parseXML", ->

    it "should call a callback", (done) ->
      parser = do getResponseParser
      parser.parseXML ->
        do done

    it "should pass parsing result to the callback", (done) ->
      parser = do getResponseParser
      parser.parseXML (error, result) ->
        expect(error).to.not.exist
        expect(result).to.be.an.instanceOf Object
        do done

    it "should pass an error if #response couldn't be parsed", (done) ->
      parser = do getResponseParser
      parser.response = '@#$@#$%@#%'
      parser.parseXML (error, result) ->
        expect(error).to.exist
        do done


  describe "#hydrate", ->

    it "should pass all parameters to #hydrateNode() and return it's result", ->
      parser = do getResponseParser
      params = [1, 2, 3]
      parser.hydrateNode = chai.spy ->
        expect(_.toArray arguments).to.be.deep.equal params
        'result'
      expect(parser.hydrate params...).to.be.equal 'result'
      expect(parser.hydrateNode).to.be.called.once

    it "should be binded to parser instance", ->
      parser = do getResponseParser
      hydrate = parser.hydrate
      parser.hydrateNode = chai.spy ->

      do hydrate

      expect(parser.hydrateNode).to.be.called.once

  describe "#hydrateNode", ->

    it "should call hydrator's #hydrate method with passed parameters " +
      "and return it's result", ->
        parser = do getResponseParser
        params = [1, 2, 3]
        spy = parser._hydrator.hydrate = chai.spy ->
          expect(_.toArray arguments).to.be.deep.equal params
          'result'
        expect(parser.hydrateNode params...).to.be.equal 'result'
        expect(spy).to.be.called.once

  describe.skip "#_exportParseResults", ->

    it "should export results to target", ->
