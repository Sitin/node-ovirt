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

  getApiHash = ->
    api:
      time: [ '2013-02-11T18:05:33.554+02:00' ]
      link: [
        { $: href: '/api/capabilities', rel: 'capabilities' }
        { $: href: '/api/clusters', rel: 'clusters' }
        { $: href: '/api/clusters?search={query}', rel: 'clusters/search' }
        { $: href: '/api/datacenters', rel: 'datacenters' }
        { $: href: '/api/datacenters?search={query}', rel: 'datacenters/search' }
        { $: href: '/api/events', rel: 'events' }
        { $: href: '/api/events;from={event_id}?search={query}', rel: 'events/search' }
        { $: href: '/api/vms', rel: 'vms' }
        { $: href: '/api/vms?search={query}', rel: 'vms/search' }
      ]
      product_info: [
        vendor: [ 'ovirt.org' ],
        name: [ 'oVirt Engine' ],
        version: [
          $:
            minor: '1',
            build: '0',
            revision: '0',
            major: '3'
        ]
      ]
      special_objects: [
        link: [
          { $: href: '/api/templates/00000000-0000-0000-0000-000000000000', rel: 'templates/blank' }
          { $: href: '/api/tags/00000000-0000-0000-0000-000000000000', rel: 'tags/root' }
        ]
      ]

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
      
      
  describe "#hydrate", ->
    it "should find collections and then export them", ->
      hydrator = getHydrator undefined, do getApiHash
      hydrator.findCollections = chai.spy ->
        return "collections"
      hydrator.exportCollections = chai.spy (collections) ->
        expect(collections).to.be.equal "collections"
        expect(hydrator.findCollections).to.have.been.called.once

      do hydrator.hydrate

      expect(hydrator.exportCollections).to.have.been.called.once


  describe "#exportCollections", ->

    it "should export specified collections to target", ->
      hydrator = do getHydrator
      hydrator._target = {}
      hydrator.exportCollections "collections"
      expect(hydrator._target).to.have.property "collections", "collections"


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
    hydrator = do getHydrator

    it "should simply return the name of the hash's root key", ->
      expect(hydrator.getRootElementName spam: Spam: 'SPAM').to.be.equal 'spam'

    it "should return undefined for hashes without single root element", ->
      expect(hydrator.getRootElementName spam: 'SPAM', eggs: 'SPAM').to.be.undefined

    it "should return undefined for empty hashes", ->
      expect(hydrator.getRootElementName {}).to.be.undefined

    it "should use instance hash property if no parameter specified", ->
      hydrator.hash = spam: Spam: 'SPAM'
      expect(do hydrator.getRootElementName).to.be.equal 'spam'

    it "should work with non-objects", ->
      hydrator.hash = null
      expect(-> hydrator.getRootElement null).to.not.throw Error
      expect(hydrator.getRootElement null).to.be.undefined


  describe "#getRootElement", ->
    hydrator = do getHydrator

    it "should return value of the hash root element", ->
      hash = spam: Spam: 'SPAM'
      expect(hydrator.getRootElement hash).to.be.equal hash.spam

    it "should return a hash itself if there no root element", ->
      hash = spam: 'SPAM', eggs: 'SPAM'
      expect(hydrator.getRootElement hash).to.be.equal hash

    it "should use instance hash property if no parameter specified", ->
      hydrator.hash = hash = spam: Spam: 'SPAM'
      expect(do hydrator.getRootElement).to.be.equal hash.spam

    it "should work with non-objects", ->
      hydrator.hash = null
      expect(-> hydrator.getRootElement null).to.not.throw Error
      expect(hydrator.getRootElement null).to.be.undefined


  describe "#findCollections", ->
    # Defaults:
    hash = do getApiHash
    hydrator = getHydrator undefined, hash
    collections = hydrator.findCollections hash

    it "should return a hash", ->
      expect(collections).to.be.an 'object'

    it "should return a hash of collections", ->
      for key of collections
        expect(collections[key]).to.be.an.instanceof OVirtCollection

    it "should return a hash of top-level only collections", ->
      expect(Object.keys(collections).length).to.be.equal 5

    it "should setup searchable collections", ->
      expect(collections.vms.isSearchable).to.be.true
      expect(collections.capabilities.isSearchable).to.be.false

    it "should use instance hash property if no parameter specified", ->
      expect(do hydrator.findCollections).to.be.deep.equal collections

    
    describe "instance methods dependencies", ->
    
      it "should use ._makeCollectionsSearchabe()", ->
        dehydrator = do getHydrator
        dehydrator._makeCollectionsSearchabe = spy =
          chai.spy dehydrator._makeCollectionsSearchabe
        dehydrator.findCollections hash
        expect(spy).to.be.called.once

      it "should skip the root element", ->
        dehydrator = do getHydrator
        dehydrator.getRootElement = spy =
          chai.spy dehydrator.getRootElement
        dehydrator.findCollections hash
        expect(spy).to.be.called

      it "should distinguish collections and search options", ->
        dehydrator = do getHydrator
        dehydrator.isSearchOption = spy =
          chai.spy dehydrator.isSearchOption
        dehydrator.findCollections hash
        expect(spy).to.be.called hash.api.link.length


  describe "#isLink", ->
    hydrator = do getHydrator

    it "should return true if both 'rel' or 'id' " +
       "and 'href' properties existed", ->
        expect(hydrator.isLink rel: "rel", href: "/href").to.be.true

    it "should omit the root element", ->
      expect(hydrator.isLink $: rel: "rel", href: "/href").to.be.true

    it "should return false for everything else", ->
      expect(hydrator.isLink rel: "rel").to.be.false
      expect(hydrator.isLink $: "eggs").to.be.false
      expect(hydrator.isLink null).to.be.false


  describe "#isCollectionLink", ->
    hydrator = do getHydrator
    id = "00000000-0000-0000-0000-000000000000"

    it "should return true if subject is a collection link", ->
      expect(hydrator.isCollectionLink rel: "rel", href: "/href").to.be.true

    it "should omit the root element", ->
      expect(hydrator.isCollectionLink $: rel: "rel", href: "href").to.be.true

    it "should return false if subject is a resource link", ->
      expect(hydrator.isCollectionLink rel: "rel", href: "/href/#{id}").to.be.false
      expect(hydrator.isCollectionLink id: id, href: "/href").to.be.false


  describe "#isResourceLink", ->
    hydrator = do getHydrator
    id = "00000000-0000-0000-0000-000000000000"

    it "should return true if subject is a resource link", ->
      subject = $: id: "id", href: "/href/#{id}"
      expect(hydrator.isResourceLink id: "id", href: "/href/#{id}").to.be.true

    it "should omit the root element", ->
      subject = $: id: "id", href: "/href/#{id}"
      expect(hydrator.isResourceLink subject).to.be.true

    it "should reflect that some resorce links " +
       "have 'rel' properties instead 'id'", ->
        subject = rel: "rel", href: "/href/#{id}"
        expect(hydrator.isResourceLink subject).to.be.true

    it "should return false for non-valid resource hrefs", ->
      subject = rel: "id", href: "/href/0000-0000-00000-000"
      expect(hydrator.isResourceLink subject).to.be.false


  describe "#_makeCollectionsSearchabe", ->
    hydrator = do getHydrator

    it "should pass searchabilities to exact collections", ->
      collections =
        eggs: {}
        spam: {}
        ham: {}
      searches =
        spam: spam: 'Spam!'
        ham: ham: 'Spam!'

      hydrator._makeCollectionsSearchabe collections, searches

      expect(collections.eggs).to.have.not.property 'searchOptions'
      expect(collections.spam).to.have.property 'searchOptions', searches.spam
      expect(collections.ham).to.have.property 'searchOptions', searches.ham

