OK here are the Node.js to oVirt driver specs.

Connection
========
1. We need one entry point object that represents an oVirt instance.
2. We want to specify "connection" parameters to that object in constructor.
3. Once this object is constructed we want to retrieve an API root resource
   object (via the lazy getter).

API root
========
4. Such call produces a special object - an API root resource.
5. Once API root object initialized we could get oVirt main properties
   withing dedicated method (getProperties).
6. Also we could access oVirt main properties directly as API root object
   own properties (via getters?).
7. Also there is .getPropertyKeys() method that return property keys.
8. All top-level oVirt collection are lazy-accessible as a hash of properties
   with getters.

Collection level
========
9. Collection getter lazy-loads oVirt collection with corresponding API call.
10. Each collection is an instance of oVirt collection class.
11. Every collection instance knows it's owner resource.
12. For the main collection an owner resource is an API root itself.
13. Collections could give access to their resources by the resource ID.
14. Also collections could list their whole content.
    But this operation could produce a large incoming traffic.
15. Resource requests are allways lazy.
16. Some collections could be searched for contained resources by their
    top-level parameters and some are not.
17. Collections could be requested to create blank resource object.

Resource level
========
18. Retrieved resource should behave as an API root except it has a link to
    it's collection.
19. Resources could be retrieved, created, updated and deleted.
20. Resources doesn't care whether their subresources are changed.
21. Every time when resource top-level parameters changed the resource
    comes to "unsaved" state.
22. Blank resources are always unsaved and also marked as "new".

Resource actions
========
23. Resources could have an actions.
24. Actions are methods that causes API calls which could change the
    resource state.
25. Complete action list could be retrieved withing dedicated method
    .getActions() (which is a getter for .actions property).

API node level
========
26. Collections and resources (both regular and the root one) are considered
    as API nodes.
27. API nodes doesn't call API during construction but could be refreshed.
28. Regular refresh doesn't affect child nodes.
29. Deep refresh implementation could be considered in future releases.
30. Every node knows it's base URI (an URI of the parent node).
31. Every node knows how to represent itself as an API URI element.
32. So, a node knows it's own dedicated API URI.
33. Every node passes it's dedicated URI to the children as their base URI
    during their construction.
34. We do not consider base URI recalculation in current release.
35. Some API nodes properties (both in collections and resources) could be
    a links to other resources. And that means that we probably should
    instantiate their collections (and maybe the owning resources of their
    collections and so on) once we retrieve them.
36. To perform API call a node requests oVirt connection to create an API
    request object, configurates it and executes.

API request
========
37. Has a link to connection to retrieve it's parameters.
38. Accepts API node and an action or operation to perform.
39. Determines request method which depend on requested operation.
40. Maps target node to XML if required.
41. Generates authentication header.
42. Could perform an HTTP(s) request.
43. Retrieves the server response, hidrates (currently uses only xml2js) it
    and then passes to target node.