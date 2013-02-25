"use strict"

# Setup chai assertions.
chai = require 'chai'
spies = require 'chai-spies'
chai.use spies
{expect} = chai

# Utilities:
_ = require 'lodash'
fs = require 'fs'

config = require '../lib/config'
{OVirtResponseHydrator, OVirtApi, OVirtApiNode, OVirtCollection, OVirtResource} = require '../lib/'

loadResponse = (name) ->
  fs.readFileSync "#{__dirname}/responses/#{name}.xml"

describe 'OVirtResponseHydrator', ->
  ATTRKEY = config.parser.attrkey

  getHydrator = (target, hash) ->
    target = new OVirtApi unless target?
    hydrator = new OVirtResponseHydrator target, hash
    # Create spies.
    for method of hydrator when _.isFunction hydrator[method]
      hydrator[method] = chai.spy hydrator[method]

    hydrator

  apiHash = require './responses/api'
  testCollection =
    link: apiHash.api.link[14]
    search: apiHash.api.link[15]
    name: apiHash.api.link[14].$.rel
    searchOptions: apiHash.api.link[15].$
  specialObjects = apiHash.api.special_objects

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

  describe "#setTarget", ->

    it "should throw an error if target couldn't be converted to OVirtApiNode", ->
        hydrator = do getHydrator
        expect(-> hydrator.setTarget "something wrong")
          .to.throw TypeError, "Hydrator's target should be an OVirtApiNode instance"

    it "should try to construct target if function specified", ->
      hydrator = do getHydrator
      spy = chai.spy OVirtApiNode
      expect(hydrator.setTarget spy).to.be.an.instanceOf OVirtApiNode
      expect(spy).to.be.called.once

    it "should treat string as a target type", ->
      hydrator = do getHydrator
      expect(hydrator.setTarget 'api').to.be.instanceOf OVirtApi


  describe "#hydrateNode", ->

    it "should call #hydrateCollectionLink and return undefined if node value is a collection link", ->
      hydrator = do getHydrator
      hydrator.isCollectionLink = -> yes
      hydrator.hydrateCollectionLink = chai.spy -> 'defined'
      expect(do hydrator.hydrateNode).to.be.undefined
      expect(hydrator.hydrateCollectionLink).to.be.called.once

    it "should call #hydrateSearchOption and return undefined if node is a search option", ->
      hydrator = do getHydrator
      hydrator.isSearchOption = -> yes
      hydrator.hydrateSearchOption = chai.spy -> 'defined'
      expect(do hydrator.hydrateNode).to.be.undefined
      expect(hydrator.hydrateSearchOption).to.be.called.once


  describe "#hydrateCollectionLink", ->

    it "should return collection object", ->
      hydrator = do getHydrator
      result = hydrator.hydrateCollectionLink '/api/link', testCollection.link
      expect(result).to.be.instanceOf OVirtCollection

    it "should register created collection", ->
      hydrator = do getHydrator
      hydrator.hydrateCollectionLink '/api/link', testCollection.link

      expect(hydrator.registerIn).to.have.been.called.once
      expect(hydrator._collections['/api/link'].instances[testCollection.name])
        .to.be.instanceOf OVirtCollection


  describe "#hydrateSearchOption", ->

    it "should return search options", ->
      hydrator = do getHydrator
      result = hydrator.hydrateSearchOption '/api/link', testCollection.search
      expect(result).to.be.equal testCollection.searchOptions

    it "should register search options", ->
      hydrator = do getHydrator
      hydrator.hydrateSearchOption '/api/link', testCollection.search

      expect(hydrator.registerIn).to.have.been.called.once
      expect(hydrator._collections['/api/link'].searchOptions)
        .to.have.property testCollection.name, testCollection.searchOptions


  describe "#registerIn", ->

    it "should throw error on incomplete parameters", ->
      hydrator = do getHydrator
      expect(hydrator.registerIn).to.throw Error,
        "You should specify both property and value to register in"
      expect(-> hydrator.registerIn 'one').to.throw Error,
        "You should specify both property and value to register in"

    it "should throw error if wrong namespace specified", ->
      hydrator = do getHydrator
      hydrator.property = 'property'
      expect(-> hydrator.registerIn 'property', 'key', 'subject')
        .to.throw Error, "Wrong namespace to register in"

    it "should throw error if object specified without a namespace", ->
      hydrator = do getHydrator
      expect(-> hydrator.registerIn hydrator._collections, 'value')
        .to.throw Error, "You should specify a namespace to register in existing object"

    it "should set property to subject if path is not specified", ->
      hydrator = do getHydrator
      hydrator.registerIn 'propertyName', 'value'
      expect(hydrator).to.have.property 'propertyName', 'value'

    it "should create property if not existed and string specified", ->
      hydrator = do getHydrator
      hydrator.registerIn 'propertyName', 'value'
      expect(hydrator).to.have.property 'propertyName', 'value'

    it "should assign subject to proper namespace", ->
      hydrator = do getHydrator
      hydrator.registerIn hydrator._collections, 'path', 'to', 'ns', 'value'
      expect(hydrator._collections).to.have.property 'path'
      expect(hydrator._collections.path).to.have.property 'to'
      expect(hydrator._collections.path.to).to.have.property 'ns', 'value'

    it "shouldn't overwrite namespaces if existed", ->
      hydrator = do getHydrator
      hydrator.registerIn hydrator._collections, 'path', 'to', 'value 1'
      hydrator.registerIn hydrator._collections, 'path', 'for', 'value 2'
      expect(hydrator._collections.path).to.have.property 'to', 'value 1'
      expect(hydrator._collections.path).to.have.property 'for', 'value 2'


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


  describe "links detection", ->
    getDeHydrator = (isLink, isResourceHref, hasChildren, attributes) ->
      attributes = {} unless attributes?
      dehydrator = do getHydrator

      dehydrator.isLink = chai.spy ->
        isLink
      dehydrator._isResourceHref = chai.spy ->
        isResourceHref
      dehydrator._hasChildElements = chai.spy ->
        hasChildren
      dehydrator._getAttributes = chai.spy -> attributes

      dehydrator


    describe "#isLink", ->
      hydrator = do getHydrator
      relLink = idLink = {}
      relLink[ATTRKEY] = rel: "rel", href: "/href"
      idLink[ATTRKEY] = id: "id", href: "/href"

      it "should return true if 'rel' and 'href' attributes existed", ->
        expect(hydrator.isLink relLink).to.be.true

      it "should return true if 'id' and 'href' attributes existed", ->
        expect(hydrator.isLink idLink).to.be.true

      it "should extract element's attributes", ->
        dehydrator = do getHydrator
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

      it.skip "should return true if is link with rel attribute and href" +
        " doesn't point to resource", ->
          hydrator = getDeHydrator yes, no, undefined, rel: '/rel'
          expect(hydrator.isCollectionLink hash).to.be.true

      it "should call every helper function to return true", ->
        hydrator = getDeHydrator yes, no, undefined, rel: '/rel'
        hydrator.isCollectionLink hash

        expect(hydrator.isLink).to.have.been.called.once
        expect(hydrator._getAttributes).to.have.been.called.once
        expect(hydrator._isResourceHref).to.have.been.called.once

      it.skip "should return false for other cases", ->
        hydrator = getDeHydrator yes, no, undefined, eggs: 'SPAM'
        expect(hydrator.isResourceLink hash).to.be.false
        hydrator = getDeHydrator no, yes, undefined, rel: '/rel'
        expect(hydrator.isResourceLink hash).to.be.false
        hydrator = getDeHydrator yes, yes, undefined, rel: '/rel'
        expect(hydrator.isResourceLink hash).to.be.false


    describe "#isResourceLink", ->
      hash = ham: "with": sausages: "and": "spam"
      attrs = spam: "SPAM"
      hash[ATTRKEY] = attrs

      it "should return true if resource related and has no children", ->
        hydrator = getDeHydrator undefined, undefined, no
        hydrator._isResourceRelated = -> true
        expect(hydrator.isResourceLink hash).to.be.true

      it "should call every helper function to return true", ->
        hydrator = getDeHydrator undefined, undefined, no
        hydrator._isResourceRelated = chai.spy ->
          true
        expect(hydrator.isResourceLink hash).to.be.true

        expect(hydrator._isResourceRelated).to.have.been.called.once
        expect(hydrator._hasChildElements).to.have.been.called.once

      it "should return false for other cases", ->
        hydrator = getDeHydrator undefined, undefined, no
        hydrator._isResourceRelated = -> false
        expect(hydrator.isResourceLink hash).to.be.false

        hydrator = getDeHydrator undefined, undefined, yes
        hydrator._isResourceRelated = -> true
        expect(hydrator.isResourceLink hash).to.be.false


    describe "#isResource", ->
      hash = ham: "with": sausages: "and": "spam"
      attrs = spam: "SPAM"
      hash[ATTRKEY] = attrs

      it "should return true if resource related and has children", ->
        hydrator = getDeHydrator undefined, undefined, yes
        hydrator._isResourceRelated = -> true
        expect(hydrator.isResource hash).to.be.true

      it "should call every helper function to return true", ->
        hydrator = getDeHydrator undefined, undefined, yes
        hydrator._isResourceRelated = chai.spy ->
          true
        expect(hydrator.isResource hash).to.be.true

        expect(hydrator._isResourceRelated).to.have.been.called.once
        expect(hydrator._hasChildElements).to.have.been.called.once

      it "should return false for other cases", ->
        hydrator = getDeHydrator undefined, undefined, yes
        hydrator._isResourceRelated = -> false
        expect(hydrator.isResource hash).to.be.false

        hydrator = getDeHydrator undefined, undefined, no
        hydrator._isResourceRelated = -> true
        expect(hydrator.isResource hash).to.be.false


    describe "#_isResourceRelated", ->
      hash = ham: "with": sausages: "and": "spam"
      attrs = spam: "SPAM"
      hash[ATTRKEY] = attrs

      it "should return true if is a link and href points to resource", ->
        hydrator = getDeHydrator yes, yes
        expect(hydrator._isResourceRelated hash).to.be.true

      it "should call every helper function to return true", ->
        hydrator = getDeHydrator yes, yes
        expect(hydrator._isResourceRelated hash).to.be.true

        expect(hydrator.isLink).to.have.been.called.once
        expect(hydrator._getAttributes).to.have.been.called.once
        expect(hydrator._isResourceHref).to.have.been.called.once

      it "should return false for other cases", ->
        hydrator = getDeHydrator no, yes
        expect(hydrator._isResourceRelated hash).to.be.false
        hydrator = getDeHydrator yes, no
        expect(hydrator._isResourceRelated hash).to.be.false


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


  describe "#_isResourceHref", ->
    hydrator = do getHydrator
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

  describe "#_getAttributes", ->
    hydrator = do getHydrator

    it "should return value of the property defined by attrkey", ->
      hash = ham: "with": sausages: "and": "SPAM"
      attributes = eggs: "SPAM"
      hash[ATTRKEY] = attributes
      expect(hydrator._getAttributes hash).to.be.equal attributes

    it "should return undefined for non-objects and arrays", ->
      expect(hydrator._getAttributes "SPAAAM!").to.be.undefined
      expect(hydrator._getAttributes []).to.be.undefined


  describe "#_hasChildElements", ->
    hydrator = do getHydrator
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
    hydrator = do getHydrator

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
    hydrator = do getHydrator

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
    hydrator = do getHydrator

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
      hydrator = do getHydrator
      hash = ham: "with": sausages: "and": "SPAM"
      hydrator._mergeAttributes = spy = chai.spy (subject) ->
        expect(subject).not.to.be.equal hash
        expect(subject).to.be.deep.equal hash

      hydrator._getPlainedElement hash

      hash[ATTRKEY] = eggs: 'spam'
      hydrator._getPlainedElement hash

      expect(spy).to.have.been.called.twice


  describe.skip "#_getSpecialObjects", ->
    hydrator = do getHydrator
    hash = hydrator.unfolded apiHash
    key = config.api.specialObjects

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



