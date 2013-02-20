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
        to.throw TypeError, "Hydrator's target should be an OVirtApiNode instance"
      
      
  describe "#hydrate", ->
    hash = do getApiHash

    it "should find collections and then export them", ->
      hydrator = getHydrator undefined, hash
      hydrator.getHydratedCollections = chai.spy ->
        return "collections"
      hydrator.exportCollections = chai.spy (collections) ->
        expect(collections).to.be.equal "collections"
        expect(hydrator.getHydratedCollections).to.have.been.called.once

      do hydrator.hydrate

      expect(hydrator.exportCollections).to.have.been.called.once

    it "should skip the root element", ->
      hydrator = getHydrator undefined, hash
      hydrator.getHydratedCollections =
        spy = chai.spy (value) ->
          expect(value).to.be.equal hydrator.unfolded hash

      hydrator.hydrate hash

      expect(spy).to.be.called.once


  describe "#exportCollections", ->

    it "should export specified collections to target", ->
      hydrator = do getHydrator
      target = new OVirtApi
      hydrator.exportCollections "collections", target
      expect(target).to.have.property "collections", "collections"

    it "should use instance property 'target' if no target specified", ->
      hydrator = do getHydrator
      hydrator.exportCollections "collections"
      expect(hydrator._target).to.have.property "collections", "collections"


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

    it "should properly process hrefs with from parts", ->
      hydrator = do getHydrator
      expect(hydrator.getSearchHrefBase "/api/events;from={event_id}?search={query}").to.be.equal "/api/events;from={event_id}?search="

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

    it "shouldn't expand a hash that contains just one array property", ->
      hydrator.hash = spam: ['SPAM']
      expect(do hydrator.getRootElementName).to.be.undefined

    it "should work with non-objects", ->
      hydrator.hash = null
      expect(-> hydrator.getRootElementName null).to.not.throw Error
      expect(hydrator.getRootElementName null).to.be.undefined
      expect(-> hydrator.getRootElementName "not an object").to.not.throw Error
      expect(hydrator.getRootElementName "not an object").to.be.undefined


  describe "#unfolded", ->
    hydrator = do getHydrator

    it "should return value of the hash root element", ->
      hash = spam: Spam: 'SPAM'
      expect(hydrator.unfolded hash).to.be.equal hash.spam

    it "should return a hash itself if there no root element", ->
      hash = spam: 'SPAM', eggs: 'SPAM'
      expect(hydrator.unfolded hash).to.be.equal hash

    it "should use instance hash property if no parameter specified", ->
      hydrator.hash = hash = spam: Spam: 'SPAM'
      expect(do hydrator.unfolded).to.be.equal hash.spam

    it "should work with non-objects", ->
      hydrator.hash = null
      expect(-> hydrator.unfolded null).to.not.throw Error
      expect(hydrator.unfolded null).to.be.undefined
      expect(-> hydrator.unfolded "not an object").to.not.throw Error


  describe "#getHydratedCollections", ->
    # Defaults:
    hash = do getApiHash
    hydrator = getHydrator undefined, hash
    hash = hydrator.unfolded hash
    collections = hydrator.getHydratedCollections hash

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

    it "should add special objects", ->
      dehydrator = do getHydrator
      {collections} = dehydrator._findCollections hash
      dehydrator._addSpecialObjects =
        spy = chai.spy (subjects, specialities) ->
          expect(Object.keys subjects).to.be.deep.equal Object.keys collections
          expect(specialities).to.be.equal hydrator._getSpecialObjects hash

      dehydrator.getHydratedCollections hash

      expect(spy).to.be.called.once

    
    describe "instance methods dependencies", ->
    
      it "should use ._makeCollectionsSearchabe()", ->
        dehydrator = do getHydrator
        dehydrator._makeCollectionsSearchabe = spy =
          chai.spy dehydrator._makeCollectionsSearchabe
        dehydrator.getHydratedCollections hash
        expect(spy).to.be.called.once

      it "should distinguish collections and search options", ->
        dehydrator = do getHydrator
        dehydrator.isSearchOption = spy =
          chai.spy dehydrator.isSearchOption
        dehydrator.getHydratedCollections hash
        expect(spy).to.be.called hash.link.length


  describe.skip "#getHydratedProperties", ->
    it "should be completed", ->


  describe "#exportProperties", ->
    it "should export hash to target's 'properties' property", ->
      hydrator = do getHydrator
      hash = eggs: "with": sausages: "and": "SPAM"
      spy = chai.spy (value) ->
        expect(value).to.be.equal hash
      hydrator.target.__defineSetter__ 'properties', spy
      hydrator.exportProperties hash
      expect(spy).to.have.been.called.once


  describe.skip "#_hydrateProperty", ->
    it "should be completed", ->


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


  describe "#isProperty", ->
    hydrator = do getHydrator

    it "should return false for special properies", ->
      for special in OVirtResponseHydrator.SPECIAL_PROPERTIES
        expect(hydrator.isProperty special).to.be.false

    it "should return true for everything else", ->
      expect(hydrator.isProperty "just_property").to.be.true


  describe "#_makeCollectionsSearchabe", ->
    hydrator = do getHydrator

    it "should pass searchabilities to exact collections", ->
      collections =
        eggs: {}
        spam: {}
        ham: {}
      searches =
        spam: href: 'Spam?search='
        ham: href: 'Spam;from{ham_id}?search='

      hydrator._makeCollectionsSearchabe collections, searches

      expect(collections.eggs).to.have.not.property 'searchOptions'
      expect(collections.spam).to.have.property('searchOptions')
        .that.deep.equals href: searches.spam.href
      expect(collections.ham).to.have.property('searchOptions')
        .that.deep.equals href: searches.ham.href


  describe "#_addSpecialObjects", ->
    hydrator = do getHydrator
    hash = hydrator.unfolded do getApiHash
    specialities = hash.special_objects
    specialsCount = specialities[0].link.length
    {collections} = hydrator._findCollections hash

    it "should loop over special objects and add them to collections", ->
      dehydrator = do getHydrator
      spy = dehydrator._addSpecialObject = chai.spy ->

      dehydrator._addSpecialObjects collections, specialities
      expect(spy).to.be.called specialsCount

    it "should clone objects before adding them", ->
      backup = _.clone
      spy = _.clone = chai.spy _.clone

      hydrator._addSpecialObjects collections, specialities
      expect(spy).to.be.called specialsCount

      _.clone = backup


  describe.skip "#_addSpecialObject", ->
    it "should be completed", ->


  describe.skip "#_setupCollections", ->
    it "should be completed", ->


  describe.skip "#_findCollections", ->
    it "should be completed", ->


  describe.skip "#_hydrateArray", ->
    it "should be completed", ->


  describe.skip "#_mergeAttributes", ->
    it "should be completed", ->


  describe.skip "#_removeSpecialProperties", ->
    it "should be completed", ->


  describe.skip "#_hydrateHash", ->
    it "should be completed", ->


  describe.skip "#_getSpecialObjects", ->
    hydrator = do getHydrator
    hash = hydrator.unfolded do getApiHash
    key = OVirtResponseHydrator.SPECIAL_OBJECTS

    it "should return value of the 'SPECIAL_OBJECTS' property", ->
      expect(hydrator._getSpecialObjects hash).to.be.equal hash[key]


  describe "#_setupResourceLink", ->
    it "should return OVirtResource instance", ->
      hydrator = do getHydrator
      expect(hydrator._setupResourceLink {}).to.be.an.instanceOf OVirtResource

    it.skip "should treat attributes as a properties", ->

    it.skip "should keep passed parameter untoched", ->


  describe "#_getSearchOptionCollectionName", ->

    it "should extract first element of the collection search link 'rel'", ->
      hydrator = do getHydrator
      expect(hydrator._getSearchOptionCollectionName "api/search").to.be.equal "api"

    it "should return udefined for non searchable paths", ->
      hydrator = do getHydrator
      expect(hydrator._getSearchOptionCollectionName "api/").to.be.undefined
      expect(hydrator._getSearchOptionCollectionName "api").to.be.undefined
      expect(hydrator._getSearchOptionCollectionName "").to.be.undefined


  describe "#_getSpecialObjectCollection", ->

    it "should extract base path from the special object's 'rel'", ->
      hydrator = do getHydrator
      expect(hydrator._getSpecialObjectCollection "api/spam").to.be.equal "api"
      expect(hydrator._getSpecialObjectCollection "if/you/want/ham/say/SPAM")
        .to.be.equal "if/you/want/ham/say"

    it "should return udefined for other paths", ->
      hydrator = do getHydrator
      expect(hydrator._getSpecialObjectCollection "api/").to.be.undefined
      expect(hydrator._getSpecialObjectCollection "api").to.be.undefined
      expect(hydrator._getSpecialObjectCollection "").to.be.undefined


  describe "#_getSpecialObjectName", ->

    it "should extract last element the special object's 'rel'", ->
      hydrator = do getHydrator
      expect(hydrator._getSpecialObjectName "eggs/spam").to.be.equal "spam"
      expect(hydrator._getSpecialObjectName "if/you/want/ham/say/SPAM")
        .to.be.equal "SPAM"

    it "should return udefined for other paths", ->
      hydrator = do getHydrator
      expect(hydrator._getSpecialObjectName "api/").to.be.undefined
      expect(hydrator._getSpecialObjectName "api").to.be.undefined
      expect(hydrator._getSpecialObjectName "").to.be.undefined



