"use strict"

# Setup chai assertions.
chai = require 'chai'
spies = require 'chai-spies'
chai.use spies
{expect} = chai

# Utilities
_ = require 'lodash'
fs = require 'fs'

# Config
config = require '../lib/config'

# SUT
{OVirtResponseHydrator} = require '../lib/'

# Dependencies
{OVirtApi, OVirtApiNode, OVirtCollection, OVirtResource} = require '../lib/'


describe 'OVirtResponseHydrator', ->
  ATTRKEY = config.parser.attrkey
  SPECIAL = config.api.specialObjects
  LINK = config.api.link
  
  # Returns response hydrator
  getHydrator = (target, hash) ->
    target = new OVirtApi unless target?
    new OVirtResponseHydrator target, hash

  # Returns response hydrator mock with spies for everything that could be
  # called.
  getHydrator.withSpies = (target, hash) ->
    hydrator = getHydrator target, hash

    # Create spies
    for method of hydrator when _.isFunction hydrator[method]
      hydrator[method] = chai.spy hydrator[method]

    hydrator

  # Returns response hydrator mock with stubs for specified functions.
  getHydrator.withSpies.andStubs = (options, target, hash) ->
    dehydrator = getHydrator.withSpies target, hash
    fn = (param) -> -> param

    # Create stubbed spies
    for key in Object.getOwnPropertyNames options
      value = options[key]
      if _.isFunction value
        stub = value
      else
        stub = fn value
      dehydrator[key] = chai.spy stub

    dehydrator

  # Test data.
  apiHash = require './responses/api'
  vmHash = require './responses/vms.ID'

  specialObjects = apiHash.api.special_objects.link
  specialObject = specialObjects[0]

  testCollection =
    link: apiHash.api.link[14]
    search: apiHash.api.link[15]
    name: apiHash.api.link[14].$.rel
    searchOptions: apiHash.api.link[15].$
    specialObject: specialObjects[0]

  resourceLinkName = 'cluster'
  resourceLink = vmHash.vm.cluster

  it "should be a function", ->
    expect(OVirtResponseHydrator).to.be.a 'function'


  describe "#constructor", ->

    it "should accept target and hash as parameters", ->
      hash = api: []
      target = new OVirtApi
      hydrator = getHydrator target, hash
      expect(hydrator).to.have.property 'hash', hash
      expect(hydrator).to.have.property 'target'
      expect(hydrator.target).to.be.not.null

    it "should create private instance properties", ->
      hydrator = do getHydrator
      expect(hydrator).to.have.property('_collections')
        .that.deep.equals {}
      expect(hydrator).to.have.property('_resourceLinks')
        .that.deep.equals {}

  describe "#setTarget", ->

    it "should throw an error if target couldn't be converted to " +
    "OVirtApiNode", ->
      hydrator = do getHydrator
      expect(-> hydrator.setTarget "something wrong")
        .to.throw TypeError,
          "Hydrator's target should be an OVirtApiNode instance"

    it "should try to construct target if function specified", ->
      hydrator = do getHydrator
      spy = chai.spy OVirtApiNode
      expect(hydrator.setTarget spy).to.be.an.instanceOf OVirtApiNode
      expect(spy).to.be.called.once

    it "should treat string as a target type", ->
      hydrator = do getHydrator
      expect(hydrator.setTarget 'api').to.be.instanceOf OVirtApi


  describe "Node hydration", ->

    describe "#hydrateNode", ->

      it "should call #hydrateCollectionLink if node is a collection link", ->
        hydrator = getHydrator.withSpies.andStubs
          isCollectionLink: yes, hydrateCollectionLink: 'defined'

        hydrator.hydrateNode 'xpath', 'old', 'value'

        expect(hydrator.isCollectionLink).to.be.called.once
        expect(hydrator.isCollectionLink).to.be.called.with 'value'
        expect(hydrator.hydrateCollectionLink).to.be.called.once

        it "should return undefined for collection links", ->
          expect(hydrator.hydrateNode 'xpath', 'old', 'value').to.be.undefined

      it "should call #hydrateSearchOption if node is a search option", ->
        hydrator = getHydrator.withSpies.andStubs
          isSearchOption: yes, hydrateSearchOption: 'defined'

        hydrator.hydrateNode 'xpath', 'old', 'value'

        expect(hydrator.isSearchOption).to.be.called.once
        expect(hydrator.isSearchOption).to.be.called.with 'value'
        expect(hydrator.hydrateSearchOption).to.be.called.once

        it "should return undefined for search options", ->
          expect(hydrator.hydrateNode 'xpath', 'old', 'value').to.be.undefined

      it "should call #hydrateSpecialObject if node is a special object", ->
        hydrator = getHydrator.withSpies.andStubs
          isSpecialObject: yes, hydrateSpecialObject: 'defined'

        hydrator.hydrateNode 'xpath', 'old', 'value'

        expect(hydrator.isSpecialObject).to.be.called.once
        expect(hydrator.isSpecialObject).to.be.called.with 'xpath', 'value'
        expect(hydrator.hydrateSpecialObject).to.be.called.once

        it "should return undefined for special objects", ->
          expect(hydrator.hydrateNode 'xpath', 'old', 'value').to.be.undefined

      it "should call #hydrateCollections if node is a collection owner", ->
        hydrator = getHydrator.withSpies.andStubs
          isCollectionsOwner: yes, hydrateCollections: undefined

        hydrator.hydrateNode 'xpath', 'old', 'value'

        expect(hydrator.isCollectionsOwner).to.be.called.once
        expect(hydrator.isCollectionsOwner).to.be.called.with 'xpath'
        expect(hydrator.hydrateCollections).to.be.called.once
        expect(hydrator.hydrateCollections).to.be.called.with 'xpath', 'value'

      it "should call #hydrateResourceLink if node is a resource link", ->
        hydrator = getHydrator.withSpies.andStubs
          isResourceLink: yes, hydrateResourceLink: 'defined'

        hydrator.hydrateNode 'xpath', 'old', 'value'

        # @todo Find the way to test whether node is resource link only once.
        expect(hydrator.isResourceLink).to.be.called.twice
        expect(hydrator.isResourceLink).to.be.called.with 'value'
        expect(hydrator.hydrateResourceLink).to.be.called.once
        expect(hydrator.hydrateResourceLink).to.be.called.with 'xpath', 'value'

        it "should return undefined for resource links", ->
          expect(hydrator.hydrateNode 'xpath', 'old', 'value').to.be.undefined

      it "shouldn't test whether node value is a resource link if it is " +
      "a special object", ->
        hydrator = getHydrator.withSpies.andStubs
          isSpecialObject: yes, hydrateSpecialObject: 'defined'
        expect(hydrator.isResourceLink).to.have.not.been.called


    describe "#hydrateCollections", ->
      # Related mock
      getCollectionsHydrator = (options) ->
        defaults =
          _getCollectionsAtXPath: 'collections'
          _getSearchOptionsAtXPath: 'searchOptions'
          _getSpecialObjectsAtXPath: 'specialObjects'
          _makeCollectionsSearchable: undefined
          _addSpecialObjects: undefined
          populateOVirtNodeLinks: undefined

        getHydrator.withSpies.andStubs _.defaults defaults, options

      it "should retrieve collections related to xpath", ->
        hydrator = do getHydrator.withSpies
        hydrator.hydrateCollections 'xpath', {}
        expect(hydrator._getCollectionsAtXPath).to.be.called.once
        expect(hydrator._getCollectionsAtXPath).to.be.called.with 'xpath'

      it "should retrieve search options related to xpath", ->
        hydrator = do getHydrator.withSpies
        hydrator.hydrateCollections 'xpath', {}
        expect(hydrator._getSearchOptionsAtXPath).to.be.called.once
        expect(hydrator._getSearchOptionsAtXPath).to.be.called.with 'xpath'

      it "should retrieve special objects related to xpath", ->
        hydrator = do getHydrator.withSpies
        hydrator.hydrateCollections 'xpath', {}
        expect(hydrator._getSpecialObjectsAtXPath).to.be.called.once
        expect(hydrator._getSpecialObjectsAtXPath).to.be.called.with 'xpath'

      it "should loop over related search options if existed and setup " +
      "corresponding collections", ->
        hydrator = do getCollectionsHydrator
        hydrator.hydrateCollections 'xpath', {}
        expect(hydrator._makeCollectionsSearchable).to.be.called.once
        expect(hydrator._makeCollectionsSearchable)
          .to.be.called.with 'collections', 'searchOptions'

      it "should loop over related sspecial objects if existed and add them " +
      "to corresponding collections", ->
        hydrator = do getCollectionsHydrator
        hydrator.hydrateCollections 'xpath', {}
        expect(hydrator._addSpecialObjects).to.be.called.once
        expect(hydrator._addSpecialObjects)
          .to.be.called.with 'collections', 'specialObjects'

      it "should compact or remove link property", ->
        hydrator = do getCollectionsHydrator
        hydrator.hydrateCollections 'xpath', {}
        expect(hydrator._cleanUpLinks).to.have.been.called.once

      it "should delete special objects element from node", ->
        hydrator = do getCollectionsHydrator
        hydrator.hydrateCollections 'xpath', {}
        expect(hydrator._cleanUpSpecialObjects).to.have.been.called.once

      it "should check whether this is a root node", ->
        hydrator = do getCollectionsHydrator
        hydrator.hydrateCollections 'xpath', {}
        expect(hydrator._isRootElememntXPath).to.have.been.called.once

      it "should export collections if this is a root node", ->
        hydrator = getCollectionsHydrator _isRootElememntXPath: yes
        hydrator._collections = xpath: instances: 'collections'
        hydrator.hydrateCollections 'xpath', {}
        expect(hydrator.exportCollections).to.be.called.once
        expect(hydrator.exportCollections).to.be.called.with 'collections'

      it.skip "should populate collections for not root node", ->
        hydrator = getCollectionsHydrator _isRootElememntXPath: no
        hydrator._collections = xpath: instances: 'collections'
        hydrator.hydrateCollections 'xpath', {}
        expect(hydrator.populateOVirtNodeLinks).to.be.called.once
        expect(hydrator.populateOVirtNodeLinks).to.be.called.with 'collections'

      it "should delete related namespace from collection instances", ->
        hydrator = do getCollectionsHydrator
        hydrator._collections["xpath"] = 'collections stuff'
        hydrator.hydrateCollections 'xpath', {}
        expect(hydrator._collections).to.have.not.property 'xpath'


    describe "#exportCollections", ->

      it "should assign collections to target's 'collection' property", ->
        hydrator = do getHydrator
        hydrator.exportCollections 'collections'
        expect(hydrator.target).to.have.property 'collections', 'collections'


    describe "#populateOVirtNodeLinks", ->
      # Test data
      hydrator = do getHydrator
      nodes = eggs: new OVirtApiNode, spam: new OVirtApiNode
      target = {}
      hydrator.populateOVirtNodeLinks nodes, target

      it "should add add getters for all API nodes with a key as a property " +
      "name", ->
        for key of nodes
          expect(target).to.have.property key, nodes[key]
          expect(target.__lookupGetter__ key).to.be.equal nodes[key].initiated


    describe "#exportProperties", ->

      it "should assign properties to target's 'properties' property", ->
        hydrator = do getHydrator
        hydrator.exportProperties 'properties'
        expect(hydrator.target).to.have.property 'properties', 'properties'


    describe "#hydrateResourceLink", ->

      it "should return a resource object", ->
        hydrator = do getHydrator
        result =
          hydrator.hydrateResourceLink '/api/name', resourceLink
        expect(result).to.be.instanceOf OVirtResource

      it "should register resource instance to corresponding namespace", ->
        hydrator = do getHydrator.withSpies
        hydrator.hydrateResourceLink '/xpath/name', resourceLink

        expect(hydrator.registerIn).to.have.been.called.once
        expect(hydrator._resourceLinks['/xpath'])
          .to.have.property('name')
          .to.be.instanceOf OVirtResource


    describe "#hydrateCollectionLink", ->

      it "should return collection object", ->
        hydrator = do getHydrator.withSpies
        result =
          hydrator.hydrateCollectionLink "/api/#{LINK}", testCollection.link
        expect(result).to.be.instanceOf OVirtCollection

      it "should register created collection", ->
        hydrator = do getHydrator.withSpies
        hydrator.hydrateCollectionLink "/api/#{LINK}", testCollection.link

        expect(hydrator.registerIn).to.have.been.called.once
        expect(hydrator._collections['/api'].instances)
          .to.have.property(testCollection.name)
          .to.be.instanceOf OVirtCollection


    describe "#hydrateSearchOption", ->

      it "should return search options", ->
        hydrator = do getHydrator.withSpies
        result =
          hydrator.hydrateSearchOption "/api/#{LINK}", testCollection.search
        expect(result).to.be.equal testCollection.searchOptions

      it "should register search options", ->
        hydrator = do getHydrator.withSpies
        hydrator.hydrateSearchOption "/api/#{LINK}", testCollection.search

        expect(hydrator.registerIn).to.have.been.called.once
        expect(hydrator._collections['/api'].searchOptions)
          .to.have.property testCollection.name, testCollection.searchOptions


    describe "#hydrateSpecialObject", ->

      it "should return special object as a resource if node " +
      "is a special object", ->
        hydrator = do getHydrator.withSpies
        result = hydrator.hydrateSpecialObject 'xpath', specialObject

        expect(result).to.be.instanceOf OVirtResource

      it "should register special object instance to corresponding " +
      "collection", ->
        hydrator = do getHydrator.withSpies
        hydrator.hydrateSpecialObject "/xpath/#{SPECIAL}/#{LINK}", specialObject

        expect(hydrator.registerIn).to.have.been.called.once
        expect(hydrator._collections['/xpath'].specialObjects)
          .to.have.property(testCollection.name)
          .to.have.property("blank")
          .to.be.instanceOf OVirtResource


    describe "#registerIn", ->

      it "should throw error on incomplete parameters", ->
        hydrator = do getHydrator.withSpies
        expect(hydrator.registerIn).to.throw Error,
          "You should specify both property and value to register in"
        expect(-> hydrator.registerIn 'one').to.throw Error,
          "You should specify both property and value to register in"

      it "should throw error if wrong namespace specified", ->
        hydrator = do getHydrator.withSpies
        hydrator.property = 'property'
        expect(-> hydrator.registerIn 'property', 'key', 'subject')
          .to.throw Error, "Wrong namespace to register in"

      it "should throw error if object specified without a namespace", ->
        hydrator = do getHydrator.withSpies
        expect(-> hydrator.registerIn hydrator._collections, 'value')
          .to.throw Error,
            "You should specify a namespace to register in existing object"

      it "should set property to subject if path is not specified", ->
        hydrator = do getHydrator.withSpies
        hydrator.registerIn 'propertyName', 'value'
        expect(hydrator).to.have.property 'propertyName', 'value'

      it "should create property if not existed and string specified", ->
        hydrator = do getHydrator.withSpies
        hydrator.registerIn 'propertyName', 'value'
        expect(hydrator).to.have.property 'propertyName', 'value'

      it "should assign subject to proper namespace", ->
        hydrator = do getHydrator.withSpies
        hydrator.registerIn hydrator._collections, 'path', 'to', 'ns', 'value'
        expect(hydrator._collections).to.have.property 'path'
        expect(hydrator._collections.path).to.have.property 'to'
        expect(hydrator._collections.path.to).to.have.property 'ns', 'value'

      it "shouldn't overwrite namespaces if existed", ->
        hydrator = do getHydrator.withSpies
        hydrator.registerIn hydrator._collections, 'path', 'to', 'value 1'
        hydrator.registerIn hydrator._collections, 'path', 'for', 'value 2'
        expect(hydrator._collections.path).to.have.property 'to', 'value 1'
        expect(hydrator._collections.path).to.have.property 'for', 'value 2'


  describe "#getSearchHrefBase", ->

    it "should return href base for specified pattern", ->
      hydrator = do getHydrator.withSpies
      expect(hydrator.getSearchHrefBase "/api/templates?search={query}")
        .to.be.equal "/api/templates?search="

    it "should properly process hrefs with from parts", ->
      hydrator = do getHydrator.withSpies
      href = "/api/events;from={event_id}?search={query}"
      expect(hydrator.getSearchHrefBase href)
          .to.be.equal "/api/events;from={event_id}?search="

    it "should return undefined for invalid patterns", ->
      hydrator = do getHydrator.withSpies
      expect(hydrator.getSearchHrefBase "").to.be.undefined
      expect(hydrator.getSearchHrefBase "/api/templates={query}")
        .to.be.undefined
      expect(hydrator.getSearchHrefBase "/api/temp????lates?search={query}")
        .to.be.undefined
      expect(hydrator.getSearchHrefBase "?/api/templates?search={query}")
        .to.be.undefined


  describe "#getRootElementName", ->
    hydrator = do getHydrator.withSpies

    it "should simply return the name of the hash's root key", ->
      expect(hydrator.getRootElementName spam: Spam: 'SPAM').to.be.equal 'spam'

    it "should return undefined for hashes without single root element", ->
      expect(hydrator.getRootElementName spam: 'SPAM', eggs: 'SPAM')
        .to.be.undefined

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
    hydrator = do getHydrator.withSpies

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


  describe "Detection of different node types", ->

    describe "#isCollectionsOwner", ->

      it "should return true if collections registered to specified xpath", ->
        hydrator = getHydrator.withSpies.andStubs _getCollectionsAtXPath: name: 'instance'
        expect(hydrator.isCollectionsOwner 'xpath').to.be.true
        expect(hydrator._getCollectionsAtXPath).to.be.called.once
        expect(hydrator._getCollectionsAtXPath).to.be.called.with 'xpath'


    describe "#isLink", ->
      hydrator = do getHydrator.withSpies
      relLink = idLink = {}
      relLink[ATTRKEY] = rel: "rel", href: "/href"
      idLink[ATTRKEY] = id: "id", href: "/href"

      it "should return true if 'rel' and 'href' attributes existed", ->
        expect(hydrator.isLink relLink).to.be.true

      it "should return true if 'id' and 'href' attributes existed", ->
        expect(hydrator.isLink idLink).to.be.true

      it "should extract element's attributes", ->
        dehydrator = do getHydrator.withSpies
        dehydrator._getAttributes = spy = chai.spy dehydrator._getAttributes
        dehydrator.isLink relLink
        expect(spy).to.be.called.once

      it "should return false for everything else", ->
        expect(hydrator.isLink rel: "rel").to.be.false
        expect(hydrator.isLink $: "eggs").to.be.false
        expect(hydrator.isLink null).to.be.false


    describe "#isCollectionLink", ->
      hash = ham: "with": sausages: "and": "spam"
      attrs = rel: "SPAM"
      hash[ATTRKEY] = attrs

      it.skip "should return true if is link with rel attribute, href " +
      "doesn't point to resource and isn't a search option", ->
        hydrator = getHydrator.withSpies.andStubs
          isLink: yes
          isSearchOption: no
          _isResourceHref: no
          _getAttributes: rel: '/rel'
        expect(hydrator.isCollectionLink hash).to.be.true

      it "should call every helper function to return true", ->
        hydrator = getHydrator.withSpies.andStubs
          isLink: yes, _isResourceHref: no, _getAttributes: rel: '/rel'
        hydrator.isCollectionLink hash

        expect(hydrator.isLink).to.have.been.called.twice
        expect(hydrator.isSearchOption).to.have.been.called.once
        expect(hydrator._getAttributes).to.have.been.called.twice
        expect(hydrator._isResourceHref).to.have.been.called.once

      it.skip "should return false for other cases", ->
        hydrator = getHydrator.withSpies.andStubs
          isLink: yes
          isSearchOption: no
          _isResourceHref: no
          _getAttributes: eggs: 'SPAM'
        expect(hydrator.isResourceLink hash).to.be.false
        hydrator = getHydrator.withSpies.andStubs
          isLink: no
          isSearchOption: no
          _isResourceHref: no
          _getAttributes: rel: '/rel'
        expect(hydrator.isResourceLink hash).to.be.false
        hydrator = getHydrator.withSpies.andStubs
          isLink: yes
          isSearchOption: no
          _isResourceHref: yes
          _getAttributes: rel: '/rel'
        expect(hydrator.isResourceLink hash).to.be.false
        hydrator = getHydrator.withSpies.andStubs
          isLink: yes
          isSearchOption: yes
          _isResourceHref: no
          _getAttributes: rel: '/rel'
        expect(hydrator.isResourceLink hash).to.be.false


    describe "#isSearchOption", ->

      it "should return true if node is a link with a search option rel", ->
        hydrator = getHydrator.withSpies.andStubs
          isLink: yes, _isSearchOptionRel: yes, _getAttributes: rel: '/rel'
        expect(do hydrator.isSearchOption).to.be.true

      it "should return false for everything else", ->
        hydrator = getHydrator.withSpies.andStubs
          isLink: yes, _isSearchOptionRel: no, _getAttributes: rel: '/rel'
        expect(do hydrator.isSearchOption).to.be.false
        hydrator = getHydrator.withSpies.andStubs
          isLink: no, _isSearchOptionRel: yes, _getAttributes: rel: '/rel'
        expect(do hydrator.isSearchOption).to.be.false
        hydrator = getHydrator.withSpies.andStubs
          isLink: yes, _isSearchOptionRel: yes, _getAttributes: undefined
        expect(do hydrator.isSearchOption).to.be.false


    describe "#_isSearchOptionRel", ->

      it "should match only valid search rel attributes", ->
        hydrator = do getHydrator.withSpies
        expect(hydrator._isSearchOptionRel "api/search").to.be.true
        expect(hydrator._isSearchOptionRel "apisearch").to.be.false
        expect(hydrator._isSearchOptionRel "api/search!").to.be.false

      it "should treat leading slash as an error", ->
        hydrator = do getHydrator.withSpies
        expect(hydrator._isSearchOptionRel "api/search/").to.be.false


    describe "#isSpecialObject", ->

      it "should return true if current xpath points to special object " +
      "contents (resource link) and node is a resource link", ->
        hydrator = getHydrator.withSpies.andStubs
          isResourceLink: yes, _isSpecialObjectXPath: yes
        expect(do hydrator.isSpecialObject).to.be.true

      it "should return false in other cases", ->
        hydrator = getHydrator.withSpies.andStubs
          isResourceLink: no, _isSpecialObjectXPath: yes
        expect(do hydrator.isSpecialObject).to.be.false
        hydrator = getHydrator.withSpies.andStubs
          isResourceLink: yes, _isSpecialObjectXPath: no
        expect(do hydrator.isSpecialObject).to.be.false


      describe "#_isSpecialObjectXPath", ->
        hydrator = do getHydrator.withSpies

        it "should return true if xpath ends with link prceded by special" +
        "object tag name", ->
          expect(hydrator._isSpecialObjectXPath "/api/#{SPECIAL}/#{LINK}")
            .to.be.true

        it "should return false in other cases", ->
          expect(hydrator._isSpecialObjectXPath "/api/regular/#{LINK}")
            .to.be.false
          expect(hydrator._isSpecialObjectXPath "/api/#{SPECIAL}/not_a_link")
            .to.be.false
          expect(hydrator._isSpecialObjectXPath "/api/path/to.nowhere")
            .to.be.false


    describe "#isResourceLink", ->
      hash = ham: "with": sausages: "and": "spam"
      attrs = spam: "SPAM"
      hash[ATTRKEY] = attrs

      it "should return true if resource related and has no children", ->
        hydrator = getHydrator.withSpies.andStubs
          _hasChildElements: no, _isResourceRelated: yes
        expect(hydrator.isResourceLink hash).to.be.true

      it "should call every helper function to return true", ->
        hydrator = getHydrator.withSpies.andStubs
          _hasChildElements: no, _isResourceRelated: yes
        expect(hydrator.isResourceLink hash).to.be.true

        expect(hydrator._isResourceRelated).to.have.been.called.once
        expect(hydrator._hasChildElements).to.have.been.called.once

      it "should return false for other cases", ->
        hydrator = getHydrator.withSpies.andStubs
          _hasChildElements: no, _isResourceRelated: no
        expect(hydrator.isResourceLink hash).to.be.false

        hydrator = getHydrator.withSpies.andStubs
          _hasChildElements: yes, _isResourceRelated: yes
        expect(hydrator.isResourceLink hash).to.be.false


    describe "#isResource", ->
      hash = ham: "with": sausages: "and": "spam"
      attrs = spam: "SPAM"
      hash[ATTRKEY] = attrs

      it "should return true if resource related and has children", ->
        hydrator = getHydrator.withSpies.andStubs
          _hasChildElements: yes, _isResourceRelated: yes
        expect(hydrator.isResource hash).to.be.true

      it "should call every helper function to return true", ->
        hydrator = getHydrator.withSpies.andStubs
          _hasChildElements: yes, _isResourceRelated: yes
        expect(hydrator.isResource hash).to.be.true

        expect(hydrator._isResourceRelated).to.have.been.called.once
        expect(hydrator._hasChildElements).to.have.been.called.once

      it "should return false for other cases", ->
        hydrator = getHydrator.withSpies.andStubs
          _hasChildElements: yes, _isResourceRelated: no
        expect(hydrator.isResource hash).to.be.false

        hydrator = getHydrator.withSpies.andStubs
          _hasChildElements: no, _isResourceRelated: yes
        expect(hydrator.isResource hash).to.be.false


    describe "#_isResourceRelated", ->
      hash = ham: "with": sausages: "and": "spam"
      attrs = spam: "SPAM"
      hash[ATTRKEY] = attrs

      it "should return true if is a link and href points to resource", ->
        hydrator = getHydrator.withSpies.andStubs isLink: yes, _isResourceHref: yes
        expect(hydrator._isResourceRelated hash).to.be.true

      it "should call every helper function to return true", ->
        hydrator = getHydrator.withSpies.andStubs isLink: yes, _isResourceHref: yes
        expect(hydrator._isResourceRelated hash).to.be.true

        expect(hydrator.isLink).to.have.been.called.once
        expect(hydrator._getAttributes).to.have.been.called.once
        expect(hydrator._isResourceHref).to.have.been.called.once

      it "should return false for other cases", ->
        hydrator = getHydrator.withSpies.andStubs isLink: no, _isResourceHref: yes
        expect(hydrator._isResourceRelated hash).to.be.false
        hydrator = getHydrator.withSpies.andStubs isLink: yes, _isResourceHref: no
        expect(hydrator._isResourceRelated hash).to.be.false


  describe "#_getCollectionsAtXPath", ->
    
    it "should return collections for given xpath", ->
      hydrator = do getHydrator
      hydrator._collections["/path/to"] = instances: 'collections'
      expect(hydrator._getCollectionsAtXPath '/path/to')
        .to.be.equal 'collections'
    
    it "should return undefined if instance namespace inaccessible", ->
      hydrator = do getHydrator
      expect(hydrator._getCollectionsAtXPath '/path/to/nowhere')
        .to.be.undefined


  describe "#_getSearchOptionsAtXPath", ->

    it "should return search options for given xpath", ->
      hydrator = do getHydrator
      hydrator._collections["/path/to"] = searchOptions: 'options'
      expect(hydrator._getSearchOptionsAtXPath '/path/to')
        .to.be.equal 'options'

    it "should return undefined if search options namespace inaccessible", ->
      hydrator = do getHydrator
      expect(hydrator._getSearchOptionsAtXPath '/path/to/nowhere')
        .to.be.undefined


  describe "#_getSpecialObjectsAtXPath", ->

    it "should return special objects for given xpath", ->
      hydrator = do getHydrator
      hydrator._collections["/path/to"] = specialObjects: 'special objects'
      expect(hydrator._getSpecialObjectsAtXPath '/path/to')
        .to.be.equal 'special objects'

    it "should return undefined if special objects namespace inaccessible", ->
      hydrator = do getHydrator
      expect(hydrator._getSpecialObjectsAtXPath '/path/to/nowhere')
        .to.be.undefined


  describe "#_isRootElememntXPath", ->

    it "should return true only for root elements xpath", ->
      hydrator = do getHydrator
      expect(hydrator._isRootElememntXPath '/api').to.be.true

    it "should return false for everything else", ->
      hydrator = do getHydrator
      expect(hydrator._isRootElememntXPath '/api/cache').to.be.false
      expect(hydrator._isRootElememntXPath '/').to.be.false
      expect(hydrator._isRootElememntXPath '').to.be.false
      expect(do hydrator._isRootElememntXPath).to.be.false

  
  describe "#_makeCollectionsSearchable", ->
    hydrator = do getHydrator.withSpies

    it "should pass searchabilities to exact collections", ->
      collections =
        eggs: {}
        spam: {}
        ham: {}
      searches =
        spam: href: 'Spam?search='
        ham: href: 'Spam;from{ham_id}?search='

      hydrator._makeCollectionsSearchable collections, searches

      expect(collections.eggs).to.have.not.property 'searchOptions'
      expect(collections.spam).to.have.property('searchOptions')
        .that.deep.equals href: searches.spam.href
      expect(collections.ham).to.have.property('searchOptions')
        .that.deep.equals href: searches.ham.href


  describe "#_addSpecialObjects", ->

    it "should loop over all special objects and add them to " +
    "respective collections", ->
      collections =
        eggs: 'eggs'
        spam: 'spam'
      specialObjects =
        eggs:
          spam: 'spam'
          ham:  'ham'
        spam:
          coffee: 'coffee'

      hydrator = getHydrator.withSpies.andStubs
        _addSpecialObject: (collection, name, object) ->
          expect(collections).to.have.property collection
          expect(specialObjects[collection]).to.have.property name
          expect(specialObjects[collection][name]).to.be.equal object

      hydrator._addSpecialObjects collections, specialObjects

      expect(hydrator._addSpecialObject).to.be.called 3


  describe "#_addSpecialObject", ->

    it "should add object to collection with specified name as a key", ->
      hydrator = do getHydrator
      collection = {}
      hydrator._addSpecialObject collection, 'key', 'value'
      expect(collection).to.have.property 'key', 'value'

    it.skip "should be completed", ->
      # @todo Complete hydrator's #_addSpecialObject tests implementation.


  describe "#_isResourceHref", ->
    hydrator = do getHydrator.withSpies
    id = "00000000-0000-0000-0000-000000000000"

    it "should return true if subject is a resource URI", ->
      expect(hydrator._isResourceHref "/href/#{id}").to.be.true
      expect(hydrator._isResourceHref "/href/to/#{id}").to.be.true

    it "should reflect that plain ID's couldn't be a resource URI", ->
      expect(hydrator._isResourceHref id).to.be.false

    it "should return false for non-valid resource hrefs", ->
      expect(hydrator._isResourceHref "/href/0000-0000-00000-000").to.be.false

    it "should false for everything else", ->
      expect(hydrator._isResourceHref '').to.be.false
      expect(hydrator._isResourceHref '/href/to').to.be.false
      expect(hydrator._isResourceHref null).to.be.false


  describe "#_cleanUpLinks", ->

    it "should remove empty vaues from link if it is an array", ->
      hydrator = do getHydrator
      node = link: [1, 2, 3, undefined, 4]
      hydrator._cleanUpLinks node
      expect(node).to.have.property("#{LINK}").that.deep.equals node.link

    it "should remove empty link array", ->
      hydrator = do getHydrator
      node = link: []
      hydrator._cleanUpLinks node
      expect(node).to.have.not.property "#{LINK}"

    it "should remove link array that have only undefined values", ->
      hydrator = do getHydrator
      node = link: [undefined, undefined]
      hydrator._cleanUpLinks node
      expect(node).to.have.not.property "#{LINK}"


  describe "#_cleanUpSpecialObjects", ->

    it "should remove special objects element", ->
      hydrator = do getHydrator
      node = {}
      node[SPECIAL] = {}
      hydrator._cleanUpSpecialObjects node
      expect(node).to.have.not.property SPECIAL


  describe "#_getAttributes", ->
    hydrator = do getHydrator.withSpies

    it "should return value of the property defined by attrkey", ->
      hash = ham: "with": sausages: "and": "SPAM"
      attributes = eggs: "SPAM"
      hash[ATTRKEY] = attributes
      expect(hydrator._getAttributes hash).to.be.equal attributes

    it "should return undefined for non-objects and arrays", ->
      expect(hydrator._getAttributes "SPAAAM!").to.be.undefined
      expect(hydrator._getAttributes []).to.be.undefined


  describe "#_hasChildElements", ->
    hydrator = do getHydrator.withSpies
    hash = ham: "with": sausages: "and": "SPAM"
    attributes = eggs: "SPAM"
    hash[ATTRKEY] = attributes

    it "should return undefined for non-objects and arrays", ->
      expect(hydrator._hasChildElements "SPAAAM!").to.be.undefined
      expect(hydrator._hasChildElements []).to.be.undefined

    it "should return true if there are properties except attributes", ->
      expect(hydrator._hasChildElements hash).to.be.true

    it "should return false for emty hashes", ->
      emptyHash = {}
      expect(hydrator._hasChildElements emptyHash).to.be.false

    it "should return false for hashes with attributes only", ->
      emptyHash = {}
      emptyHash[ATTRKEY] = attributes
      expect(hydrator._hasChildElements emptyHash).to.be.false


  describe "#_hasAttributes", ->
    hydrator = do getHydrator.withSpies

    it "should return undefined for non-objects and arrays", ->
      expect(hydrator._hasAttributes "SPAAAM!").to.be.undefined
      expect(hydrator._hasAttributes []).to.be.undefined

    it "should return true if there are property with attrkey", ->
      hash = ham: "with": sausages: "and": "SPAM"
      hash[ATTRKEY] = spam: "eggs"
      expect(hydrator._hasAttributes hash).to.be.true

    it "should return true if attributes is an only property", ->
      hash = {}
      hash[ATTRKEY] = spam: "spam"
      expect(hydrator._hasAttributes hash).to.be.true

    it "should return false in other cases", ->
      hash = ham: "with": sausages: "and": "SPAM"
      emptyHash = {}
      expect(hydrator._hasAttributes hash).to.be.false
      expect(hydrator._hasAttributes emptyHash).to.be.false


  describe "#_getElementChildren", ->
    hydrator = do getHydrator.withSpies

    it "should return undefined for non-objects and arrays", ->
      expect(hydrator._getElementChildren "SPAAAM!").to.be.undefined
      expect(hydrator._getElementChildren []).to.be.undefined

    it "should return an object for any passed object", ->
      expect(hydrator._getElementChildren {}).to.be.an.object

    it "should return children elements if existed", ->
      children = ham: "with": sausages: "and": "SPAM"
      hash = _.clone children
      hash[ATTRKEY] = eggs: "SPAM"
      expect(hydrator._getElementChildren children).to.be.deep.equal children
      expect(hydrator._getElementChildren hash).to.be.deep.equal children


  describe "#_mergeAttributes", ->
    hydrator = do getHydrator.withSpies

    it "should return undefined for non-objects and arrays", ->
      expect(hydrator._mergeAttributes "SPAAAM!").to.be.undefined
      expect(hydrator._mergeAttributes []).to.be.undefined

    it "should return an object for any passed object", ->
      expect(hydrator._mergeAttributes eggs: 'spam').to.be.an.object

    it "should return the same object as passed", ->
      hash = ham: "with": sausages: "and": "SPAM"
      expect(hydrator._mergeAttributes hash).to.be.equal hash

      hash[ATTRKEY] = eggs: 'spam'
      expect(hydrator._mergeAttributes hash).to.be.equal hash

    it "should keep objects without attributes untouched", ->
      hash = ham: "with": sausages: "and": "SPAM"
      expect(hydrator._mergeAttributes hash).to.be.deep.equal hash

    it "should delete propery with attrkey", ->
      hash = ham: "with": sausages: "and": "SPAM"
      hash[ATTRKEY] = spam: "spam"
      expect(hydrator._mergeAttributes hash).not.to.have.property ATTRKEY

    it "should merge attributes with children", ->
      children = ham: "with": sausages: "and": "SPAM"
      attrs = spam: "spam"
      hash = _.clone children
      hash[ATTRKEY] = attrs

      expect(hydrator._mergeAttributes hash)
        .to.be.deep.equal _.merge {}, children, attrs


  describe "#_getPlainedElement", ->

    it "should clone passed object and merge their attributes", ->
      hydrator = do getHydrator.withSpies
      hash = ham: "with": sausages: "and": "SPAM"
      hydrator._mergeAttributes = spy = chai.spy (subject) ->
        expect(subject).not.to.be.equal hash
        expect(subject).to.be.deep.equal hash

      hydrator._getPlainedElement hash

      hash[ATTRKEY] = eggs: 'spam'
      hydrator._getPlainedElement hash

      expect(spy).to.have.been.called.twice


  describe "#_setupResourceLink", ->
    it "should return OVirtResource instance", ->
      hydrator = do getHydrator.withSpies
      expect(hydrator._setupResourceLink {}).to.be.an.instanceOf OVirtResource

    it.skip "should treat attributes as a properties", ->

    it.skip "should keep passed parameter untoched", ->

