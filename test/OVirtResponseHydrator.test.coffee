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
  getHydrator = (target, hash) ->
    target = new OVirtApi unless target?
    new OVirtResponseHydrator target, hash

  it "should be a function", ->
    expect(OVirtResponseHydrator).to.be.a 'function'


  describe "#constructor", ->

    it "should accept target and hash as parameters", ->
      hash = api: []
      target = new OVirtApi
      hydrator = getHydrator target, hash
      expect(hydrator).to.have.property 'hash', hash
      expect(hydrator).to.have.property 'target', target

    it "should restrict target to OVirtApiNode instances", ->
      expect(-> getHydrator {}).
        to.throw "Hydrator's target should be an OVirtApiNode instance"


  describe "#getSearchOptionCollectionName", ->

    it "should extract first element of the collection search link 'rel'", ->
      hydrator = do getHydrator
      expect(hydrator.getSearchOptionCollectionName "api/search").to.be.equal "api"

    it "should return udefined for non searchable paths", ->
      hydrator = do getHydrator
      expect(hydrator.getSearchOptionCollectionName "api/").to.be.undefined
      expect(hydrator.getSearchOptionCollectionName "api").to.be.undefined
      expect(hydrator.getSearchOptionCollectionName "").to.be.undefined


  describe "#isSearchOption", ->

    it "should match only valid search rel attributes", ->
      hydrator = do getHydrator
      expect(hydrator.isSearchOption "api/search").to.be.true
      expect(hydrator.isSearchOption "apisearch").to.be.false
      expect(hydrator.isSearchOption "api/search!").to.be.false

    it "should treat leading slash as an error", ->
      hydrator = do getHydrator
      expect(hydrator.isSearchOption "api/search/").to.be.false


  describe "#getSearchHrefBase", ->

    it "should return href base for specified pattern", ->
      hydrator = do getHydrator
      expect(hydrator.getSearchHrefBase "/api/templates?search={query}").to.be.equal "/api/templates?search="

    it "should return undefined for invalid patterns", ->
      hydrator = do getHydrator
      expect(hydrator.getSearchHrefBase "").to.be.undefined
      expect(hydrator.getSearchHrefBase "/api/templates={query}").to.be.undefined
      expect(hydrator.getSearchHrefBase "/api/temp????lates?search={query}").to.be.undefined
      expect(hydrator.getSearchHrefBase "?/api/templates?search={query}").to.be.undefined


  describe "#getRootElementName", ->

    it "should simply return the name of the hash's root key", ->
      hydrator = do getHydrator
      expect(hydrator.getRootElementName spam: Spam: 'SPAM').to.be.equal 'spam'

    it "should return undefined for hashes without single root element", ->
      hydrator = do getHydrator
      expect(hydrator.getRootElementName spam: 'SPAM', eggs: 'SPAM').to.be.undefined

    it "should return undefined for empty hashes", ->
      hydrator = do getHydrator
      expect(hydrator.getRootElementName {}).to.be.undefined

    it "should use instance hash property if no parameter specified", ->
      hash = spam: Spam: 'SPAM'
      hydrator = getHydrator undefined, hash
      expect(do hydrator.getRootElementName).to.be.equal 'spam'


  describe "#getRootElement", ->

    it "should return value of the hash root element", ->
      hydrator = do getHydrator
      hash = spam: Spam: 'SPAM'
      expect(hydrator.getRootElement hash).to.be.equal hash.spam

    it "should return a hash itself if there no root element", ->
      hydrator = do getHydrator
      hash = spam: 'SPAM', eggs: 'SPAM'
      expect(hydrator.getRootElement hash).to.be.equal hash

    it "should use instance hash property if no parameter specified", ->
      hash = spam: Spam: 'SPAM'
      hydrator = getHydrator undefined, hash
      expect(do hydrator.getRootElement).to.be.equal hash.spam


  describe "#findArrayOfCollections", ->


