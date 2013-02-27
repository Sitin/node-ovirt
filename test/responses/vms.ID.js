module.exports =
{
  vm: {
    template: {
      $: { id: '00000000-0000-0000-0000-000000000000', href: '/api/templates/00000000-0000-0000-0000-000000000000' }
    },
    display: {
      port: '5900',
      type: 'spice',
      address: 'virtmanager.tigerrr.int',
      secure_port: '5901',
      monitors: '1',
      allow_reconnect: 'false'
    },
    link: [
      {
        $: { rel: 'disks', href: '/api/vms/aa4ea946-0a71-489e-abed-40136c84e4e7/disks' }
      },
      {
        $: { rel: 'nics', href: '/api/vms/aa4ea946-0a71-489e-abed-40136c84e4e7/nics' }
      },
      {
        $: { rel: 'cdroms', href: '/api/vms/aa4ea946-0a71-489e-abed-40136c84e4e7/cdroms' }
      },
      {
        $: { rel: 'snapshots', href: '/api/vms/aa4ea946-0a71-489e-abed-40136c84e4e7/snapshots' }
      },
      {
        $: { rel: 'tags', href: '/api/vms/aa4ea946-0a71-489e-abed-40136c84e4e7/tags' }
      },
      {
        $: { rel: 'permissions', href: '/api/vms/aa4ea946-0a71-489e-abed-40136c84e4e7/permissions' }
      },
      {
        $: { rel: 'statistics', href: '/api/vms/aa4ea946-0a71-489e-abed-40136c84e4e7/statistics' }
      }
    ],
    type: 'desktop',
    cluster: {
      $: { id: '0fda9d72-7430-11e2-9d4e-3085a99aa783', href: '/api/clusters/0fda9d72-7430-11e2-9d4e-3085a99aa783' }
    },
    placement_policy: { affinity: 'migratable' },
    memory: '1073741824',
    status: { state: 'down' },
    high_availability: { enabled: 'false', priority: '1' },
    creation_time: '2013-02-11T12:20:29.664+02:00',
    memory_policy: { ballooning: 'true', guaranteed: '536870912' },
    actions: {
      link: [
        {
          $: { rel: 'ticket', href: '/api/vms/aa4ea946-0a71-489e-abed-40136c84e4e7/ticket' }
        },
        {
          $: { rel: 'cancelmigration', href: '/api/vms/aa4ea946-0a71-489e-abed-40136c84e4e7/cancelmigration' }
        },
        {
          $: { rel: 'migrate', href: '/api/vms/aa4ea946-0a71-489e-abed-40136c84e4e7/migrate' }
        },
        {
          $: { rel: 'shutdown', href: '/api/vms/aa4ea946-0a71-489e-abed-40136c84e4e7/shutdown' }
        },
        {
          $: { rel: 'start', href: '/api/vms/aa4ea946-0a71-489e-abed-40136c84e4e7/start' }
        },
        {
          $: { rel: 'stop', href: '/api/vms/aa4ea946-0a71-489e-abed-40136c84e4e7/stop' }
        },
        {
          $: { rel: 'suspend', href: '/api/vms/aa4ea946-0a71-489e-abed-40136c84e4e7/suspend' }
        },
        {
          $: { rel: 'detach', href: '/api/vms/aa4ea946-0a71-489e-abed-40136c84e4e7/detach' }
        },
        {
          $: { rel: 'export', href: '/api/vms/aa4ea946-0a71-489e-abed-40136c84e4e7/export' }
        },
        {
          $: { rel: 'move', href: '/api/vms/aa4ea946-0a71-489e-abed-40136c84e4e7/move' }
        }
      ]
    },
    stateless: 'false',
    os: {
      kernel: {},
      boot: {
        $: { dev: 'hd' }
      },
      initrd: {},
      $: { type: 'rhel_6x64' },
      cmdline: {}
    },
    origin: 'ovirt',
    name: 'east-vm',
    quota: {
      $: { id: '61095ffa-e4ac-4ecc-bbb2-fe48399a410e' }
    },
    usb: { enabled: 'false' },
    $: { id: 'aa4ea946-0a71-489e-abed-40136c84e4e7', href: '/api/vms/aa4ea946-0a71-489e-abed-40136c84e4e7' },
    cpu: {
      topology: {
        $: { sockets: '1', cores: '1' }
      }
    }
  }
}

