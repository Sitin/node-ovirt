module.exports =
{
  api: {
    time:            '2013-02-11T18:05:33.554+02:00',
    special_objects: {
      link: [
        {
          $: { rel: 'templates/blank', href: '/api/templates/00000000-0000-0000-0000-000000000000' }
        },
        {
          $: { rel: 'tags/root', href: '/api/tags/00000000-0000-0000-0000-000000000000' }
        }
      ]
    },
    summary:         {
      storage_domains: { total: '3', active: '2' },
      vms:             { total: '5', active: '0' },
      hosts:           { total: '2', active: '1' },
      users:           { total: '3', active: '2' }
    },
    product_info:    {
      vendor:  'ovirt.org',
      version: {
        $: {
          major:    '3',
          revision: '0',
          minor:    '1',
          build:    '0'
        }
      },
      name:    'oVirt Engine'
    },
    link:            [
      {
        $: { rel: 'capabilities', href: '/api/capabilities' }
      },
      {
        $: { rel: 'clusters', href: '/api/clusters' }
      },
      {
        $: { rel: 'clusters/search', href: '/api/clusters?search={query}' }
      },
      {
        $: { rel: 'datacenters', href: '/api/datacenters' }
      },
      {
        $: { rel: 'datacenters/search', href: '/api/datacenters?search={query}' }
      },
      {
        $: { rel: 'events', href: '/api/events' }
      },
      {
        $: { rel: 'events/search', href: '/api/events;from={event_id}?search={query}' }
      },
      {
        $: { rel: 'hosts', href: '/api/hosts' }
      },
      {
        $: { rel: 'hosts/search', href: '/api/hosts?search={query}' }
      },
      {
        $: { rel: 'networks', href: '/api/networks' }
      },
      {
        $: { rel: 'roles', href: '/api/roles' }
      },
      {
        $: { rel: 'storagedomains', href: '/api/storagedomains' }
      },
      {
        $: { rel: 'storagedomains/search', href: '/api/storagedomains?search={query}' }
      },
      {
        $: { rel: 'tags', href: '/api/tags' }
      },
      {
        $: { rel: 'templates', href: '/api/templates' }
      },
      {
        $: { rel: 'templates/search', href: '/api/templates?search={query}' }
      },
      {
        $: { rel: 'users', href: '/api/users' }
      },
      {
        $: { rel: 'users/search', href: '/api/users?search={query}' }
      },
      {
        $: { rel: 'groups', href: '/api/groups' }
      },
      {
        $: { rel: 'groups/search', href: '/api/groups?search={query}' }
      },
      {
        $: { rel: 'domains', href: '/api/domains' }
      },
      {
        $: { rel: 'vmpools', href: '/api/vmpools' }
      },
      {
        $: { rel: 'vmpools/search', href: '/api/vmpools?search={query}' }
      },
      {
        $: { rel: 'vms', href: '/api/vms' }
      },
      {
        $: { rel: 'vms/search', href: '/api/vms?search={query}' }
      },
      {
        $: { rel: 'disks', href: '/api/disks' }
      },
      {
        $: { rel: 'disks/search', href: '/api/disks?search={query}' }
      }
    ]
  }
}
