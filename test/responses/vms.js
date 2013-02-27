module.exports =
{
  vms: {
    vm: [
      {
        $: { href: '/api/vms/aa4ea946-0a71-489e-abed-40136c84e4e7', id: 'aa4ea946-0a71-489e-abed-40136c84e4e7' },
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
        status: { state: 'down' },
        cluster: {
          $: { href: '/api/clusters/0fda9d72-7430-11e2-9d4e-3085a99aa783', id: '0fda9d72-7430-11e2-9d4e-3085a99aa783' }
        },
        origin: 'ovirt',
        type: 'desktop',
        display: {
          allow_reconnect: 'false',
          secure_port: '5901',
          monitors: '1',
          type: 'spice',
          address: 'virtmanager.tigerrr.int',
          port: '5900'
        },
        template: {
          $: { href: '/api/templates/00000000-0000-0000-0000-000000000000', id: '00000000-0000-0000-0000-000000000000' }
        },
        usb: { enabled: 'false' },
        os: {
          cmdline: {},
          kernel: {},
          $: { type: 'rhel_6x64' },
          initrd: {},
          boot: {
            $: { dev: 'hd' }
          }
        },
        memory_policy: { guaranteed: '536870912' },
        cpu: {
          topology: {
            $: { cores: '1', sockets: '1' }
          }
        },
        quota: {
          $: { id: '61095ffa-e4ac-4ecc-bbb2-fe48399a410e' }
        },
        placement_policy: { affinity: 'migratable' },
        creation_time: '2013-02-11T12:20:29.664+02:00',
        memory: '1073741824',
        name: 'east-vm',
        high_availability: { enabled: 'false', priority: '1' },
        stateless: 'false'
      },
      {
        $: { href: '/api/vms/00b6c933-02e9-4ff5-9a88-95cca0e1afca', id: '00b6c933-02e9-4ff5-9a88-95cca0e1afca' },
        link: [
          {
            $: { rel: 'disks', href: '/api/vms/00b6c933-02e9-4ff5-9a88-95cca0e1afca/disks' }
          },
          {
            $: { rel: 'nics', href: '/api/vms/00b6c933-02e9-4ff5-9a88-95cca0e1afca/nics' }
          },
          {
            $: { rel: 'cdroms', href: '/api/vms/00b6c933-02e9-4ff5-9a88-95cca0e1afca/cdroms' }
          },
          {
            $: { rel: 'snapshots', href: '/api/vms/00b6c933-02e9-4ff5-9a88-95cca0e1afca/snapshots' }
          },
          {
            $: { rel: 'tags', href: '/api/vms/00b6c933-02e9-4ff5-9a88-95cca0e1afca/tags' }
          },
          {
            $: { rel: 'permissions', href: '/api/vms/00b6c933-02e9-4ff5-9a88-95cca0e1afca/permissions' }
          },
          {
            $: { rel: 'statistics', href: '/api/vms/00b6c933-02e9-4ff5-9a88-95cca0e1afca/statistics' }
          }
        ],
        actions: {
          link: [
            {
              $: { rel: 'ticket', href: '/api/vms/00b6c933-02e9-4ff5-9a88-95cca0e1afca/ticket' }
            },
            {
              $: { rel: 'cancelmigration', href: '/api/vms/00b6c933-02e9-4ff5-9a88-95cca0e1afca/cancelmigration' }
            },
            {
              $: { rel: 'migrate', href: '/api/vms/00b6c933-02e9-4ff5-9a88-95cca0e1afca/migrate' }
            },
            {
              $: { rel: 'shutdown', href: '/api/vms/00b6c933-02e9-4ff5-9a88-95cca0e1afca/shutdown' }
            },
            {
              $: { rel: 'start', href: '/api/vms/00b6c933-02e9-4ff5-9a88-95cca0e1afca/start' }
            },
            {
              $: { rel: 'stop', href: '/api/vms/00b6c933-02e9-4ff5-9a88-95cca0e1afca/stop' }
            },
            {
              $: { rel: 'suspend', href: '/api/vms/00b6c933-02e9-4ff5-9a88-95cca0e1afca/suspend' }
            },
            {
              $: { rel: 'detach', href: '/api/vms/00b6c933-02e9-4ff5-9a88-95cca0e1afca/detach' }
            },
            {
              $: { rel: 'export', href: '/api/vms/00b6c933-02e9-4ff5-9a88-95cca0e1afca/export' }
            },
            {
              $: { rel: 'move', href: '/api/vms/00b6c933-02e9-4ff5-9a88-95cca0e1afca/move' }
            }
          ]
        },
        status: { state: 'down' },
        cluster: {
          $: { href: '/api/clusters/0fda9d72-7430-11e2-9d4e-3085a99aa783', id: '0fda9d72-7430-11e2-9d4e-3085a99aa783' }
        },
        origin: 'ovirt',
        type: 'server',
        display: {
          allow_reconnect: 'true',
          monitors: '1',
          type: 'spice'
        },
        template: {
          $: { href: '/api/templates/00000000-0000-0000-0000-000000000000', id: '00000000-0000-0000-0000-000000000000' }
        },
        usb: { enabled: 'false' },
        os: {
          cmdline: {},
          kernel: {},
          $: { type: 'other_linux' },
          initrd: {},
          boot: {
            $: { dev: 'hd' }
          }
        },
        memory_policy: { guaranteed: '268435456' },
        cpu: {
          topology: {
            $: { cores: '1', sockets: '1' }
          }
        },
        quota: {
          $: { id: '61095ffa-e4ac-4ecc-bbb2-fe48399a410e' }
        },
        placement_policy: { affinity: 'migratable' },
        creation_time: '2013-02-11T18:03:42.778+02:00',
        memory: '536870912',
        name: 'not-ready-vm',
        high_availability: { enabled: 'false', priority: '1' },
        stateless: 'false'
      },
      {
        $: { href: '/api/vms/63d93b5e-50f3-47cd-a323-34422ca14c6d', id: '63d93b5e-50f3-47cd-a323-34422ca14c6d' },
        link: [
          {
            $: { rel: 'disks', href: '/api/vms/63d93b5e-50f3-47cd-a323-34422ca14c6d/disks' }
          },
          {
            $: { rel: 'nics', href: '/api/vms/63d93b5e-50f3-47cd-a323-34422ca14c6d/nics' }
          },
          {
            $: { rel: 'cdroms', href: '/api/vms/63d93b5e-50f3-47cd-a323-34422ca14c6d/cdroms' }
          },
          {
            $: { rel: 'snapshots', href: '/api/vms/63d93b5e-50f3-47cd-a323-34422ca14c6d/snapshots' }
          },
          {
            $: { rel: 'tags', href: '/api/vms/63d93b5e-50f3-47cd-a323-34422ca14c6d/tags' }
          },
          {
            $: { rel: 'permissions', href: '/api/vms/63d93b5e-50f3-47cd-a323-34422ca14c6d/permissions' }
          },
          {
            $: { rel: 'statistics', href: '/api/vms/63d93b5e-50f3-47cd-a323-34422ca14c6d/statistics' }
          }
        ],
        actions: {
          link: [
            {
              $: { rel: 'ticket', href: '/api/vms/63d93b5e-50f3-47cd-a323-34422ca14c6d/ticket' }
            },
            {
              $: { rel: 'cancelmigration', href: '/api/vms/63d93b5e-50f3-47cd-a323-34422ca14c6d/cancelmigration' }
            },
            {
              $: { rel: 'migrate', href: '/api/vms/63d93b5e-50f3-47cd-a323-34422ca14c6d/migrate' }
            },
            {
              $: { rel: 'shutdown', href: '/api/vms/63d93b5e-50f3-47cd-a323-34422ca14c6d/shutdown' }
            },
            {
              $: { rel: 'start', href: '/api/vms/63d93b5e-50f3-47cd-a323-34422ca14c6d/start' }
            },
            {
              $: { rel: 'stop', href: '/api/vms/63d93b5e-50f3-47cd-a323-34422ca14c6d/stop' }
            },
            {
              $: { rel: 'suspend', href: '/api/vms/63d93b5e-50f3-47cd-a323-34422ca14c6d/suspend' }
            },
            {
              $: { rel: 'detach', href: '/api/vms/63d93b5e-50f3-47cd-a323-34422ca14c6d/detach' }
            },
            {
              $: { rel: 'export', href: '/api/vms/63d93b5e-50f3-47cd-a323-34422ca14c6d/export' }
            },
            {
              $: { rel: 'move', href: '/api/vms/63d93b5e-50f3-47cd-a323-34422ca14c6d/move' }
            }
          ]
        },
        status: { state: 'down' },
        cluster: {
          $: { href: '/api/clusters/0fda9d72-7430-11e2-9d4e-3085a99aa783', id: '0fda9d72-7430-11e2-9d4e-3085a99aa783' }
        },
        origin: 'ovirt',
        type: 'desktop',
        display: {
          allow_reconnect: 'false',
          secure_port: '5903',
          monitors: '1',
          type: 'spice',
          address: 'virtmanager.tigerrr.int',
          port: '5902'
        },
        template: {
          $: { href: '/api/templates/00000000-0000-0000-0000-000000000000', id: '00000000-0000-0000-0000-000000000000' }
        },
        usb: { enabled: 'false' },
        os: {
          cmdline: {},
          kernel: {},
          $: { type: 'other_linux' },
          initrd: {},
          boot: {
            $: { dev: 'hd' }
          }
        },
        memory_policy: { guaranteed: '536870912' },
        cpu: {
          topology: {
            $: { cores: '1', sockets: '1' }
          }
        },
        quota: {
          $: { id: '61095ffa-e4ac-4ecc-bbb2-fe48399a410e' }
        },
        placement_policy: { affinity: 'migratable' },
        creation_time: '2013-02-11T12:11:33.725+02:00',
        memory: '1073741824',
        name: 'test-vm',
        high_availability: { enabled: 'false', priority: '1' },
        stateless: 'false'
      },
      {
        $: { href: '/api/vms/218cc8f0-809b-44f6-a73c-1f1971e2664f', id: '218cc8f0-809b-44f6-a73c-1f1971e2664f' },
        link: [
          {
            $: { rel: 'disks', href: '/api/vms/218cc8f0-809b-44f6-a73c-1f1971e2664f/disks' }
          },
          {
            $: { rel: 'nics', href: '/api/vms/218cc8f0-809b-44f6-a73c-1f1971e2664f/nics' }
          },
          {
            $: { rel: 'cdroms', href: '/api/vms/218cc8f0-809b-44f6-a73c-1f1971e2664f/cdroms' }
          },
          {
            $: { rel: 'snapshots', href: '/api/vms/218cc8f0-809b-44f6-a73c-1f1971e2664f/snapshots' }
          },
          {
            $: { rel: 'tags', href: '/api/vms/218cc8f0-809b-44f6-a73c-1f1971e2664f/tags' }
          },
          {
            $: { rel: 'permissions', href: '/api/vms/218cc8f0-809b-44f6-a73c-1f1971e2664f/permissions' }
          },
          {
            $: { rel: 'statistics', href: '/api/vms/218cc8f0-809b-44f6-a73c-1f1971e2664f/statistics' }
          }
        ],
        actions: {
          link: [
            {
              $: { rel: 'ticket', href: '/api/vms/218cc8f0-809b-44f6-a73c-1f1971e2664f/ticket' }
            },
            {
              $: { rel: 'cancelmigration', href: '/api/vms/218cc8f0-809b-44f6-a73c-1f1971e2664f/cancelmigration' }
            },
            {
              $: { rel: 'migrate', href: '/api/vms/218cc8f0-809b-44f6-a73c-1f1971e2664f/migrate' }
            },
            {
              $: { rel: 'shutdown', href: '/api/vms/218cc8f0-809b-44f6-a73c-1f1971e2664f/shutdown' }
            },
            {
              $: { rel: 'start', href: '/api/vms/218cc8f0-809b-44f6-a73c-1f1971e2664f/start' }
            },
            {
              $: { rel: 'stop', href: '/api/vms/218cc8f0-809b-44f6-a73c-1f1971e2664f/stop' }
            },
            {
              $: { rel: 'suspend', href: '/api/vms/218cc8f0-809b-44f6-a73c-1f1971e2664f/suspend' }
            },
            {
              $: { rel: 'detach', href: '/api/vms/218cc8f0-809b-44f6-a73c-1f1971e2664f/detach' }
            },
            {
              $: { rel: 'export', href: '/api/vms/218cc8f0-809b-44f6-a73c-1f1971e2664f/export' }
            },
            {
              $: { rel: 'move', href: '/api/vms/218cc8f0-809b-44f6-a73c-1f1971e2664f/move' }
            }
          ]
        },
        status: { state: 'down' },
        cluster: {
          $: { href: '/api/clusters/a05577a2-7442-11e2-be15-3085a99aa783', id: 'a05577a2-7442-11e2-be15-3085a99aa783' }
        },
        origin: 'ovirt',
        type: 'desktop',
        display: {
          allow_reconnect: 'false',
          secure_port: '5901',
          monitors: '1',
          type: 'spice',
          address: '192.168.2.61',
          port: '5900'
        },
        template: {
          $: { href: '/api/templates/00000000-0000-0000-0000-000000000000', id: '00000000-0000-0000-0000-000000000000' }
        },
        usb: { enabled: 'false' },
        os: {
          cmdline: {},
          kernel: {},
          $: { type: 'other_linux' },
          initrd: {},
          boot: {
            $: { dev: 'hd' }
          }
        },
        memory_policy: { guaranteed: '1073741824' },
        cpu: {
          topology: {
            $: { cores: '1', sockets: '1' }
          }
        },
        quota: {
          $: { id: 'db60f41c-2695-44e5-9dcc-c059a3713bf7' }
        },
        placement_policy: { affinity: 'migratable' },
        creation_time: '2013-02-11T15:06:57.362+02:00',
        memory: '1073741824',
        name: 'test-vm1',
        high_availability: { enabled: 'false', priority: '1' },
        stateless: 'false'
      },
      {
        $: { href: '/api/vms/dfda614f-6b4d-4fe7-a8dc-e8bb636d1df1', id: 'dfda614f-6b4d-4fe7-a8dc-e8bb636d1df1' },
        link: [
          {
            $: { rel: 'disks', href: '/api/vms/dfda614f-6b4d-4fe7-a8dc-e8bb636d1df1/disks' }
          },
          {
            $: { rel: 'nics', href: '/api/vms/dfda614f-6b4d-4fe7-a8dc-e8bb636d1df1/nics' }
          },
          {
            $: { rel: 'cdroms', href: '/api/vms/dfda614f-6b4d-4fe7-a8dc-e8bb636d1df1/cdroms' }
          },
          {
            $: { rel: 'snapshots', href: '/api/vms/dfda614f-6b4d-4fe7-a8dc-e8bb636d1df1/snapshots' }
          },
          {
            $: { rel: 'tags', href: '/api/vms/dfda614f-6b4d-4fe7-a8dc-e8bb636d1df1/tags' }
          },
          {
            $: { rel: 'permissions', href: '/api/vms/dfda614f-6b4d-4fe7-a8dc-e8bb636d1df1/permissions' }
          },
          {
            $: { rel: 'statistics', href: '/api/vms/dfda614f-6b4d-4fe7-a8dc-e8bb636d1df1/statistics' }
          }
        ],
        actions: {
          link: [
            {
              $: { rel: 'ticket', href: '/api/vms/dfda614f-6b4d-4fe7-a8dc-e8bb636d1df1/ticket' }
            },
            {
              $: { rel: 'cancelmigration', href: '/api/vms/dfda614f-6b4d-4fe7-a8dc-e8bb636d1df1/cancelmigration' }
            },
            {
              $: { rel: 'migrate', href: '/api/vms/dfda614f-6b4d-4fe7-a8dc-e8bb636d1df1/migrate' }
            },
            {
              $: { rel: 'shutdown', href: '/api/vms/dfda614f-6b4d-4fe7-a8dc-e8bb636d1df1/shutdown' }
            },
            {
              $: { rel: 'start', href: '/api/vms/dfda614f-6b4d-4fe7-a8dc-e8bb636d1df1/start' }
            },
            {
              $: { rel: 'stop', href: '/api/vms/dfda614f-6b4d-4fe7-a8dc-e8bb636d1df1/stop' }
            },
            {
              $: { rel: 'suspend', href: '/api/vms/dfda614f-6b4d-4fe7-a8dc-e8bb636d1df1/suspend' }
            },
            {
              $: { rel: 'detach', href: '/api/vms/dfda614f-6b4d-4fe7-a8dc-e8bb636d1df1/detach' }
            },
            {
              $: { rel: 'export', href: '/api/vms/dfda614f-6b4d-4fe7-a8dc-e8bb636d1df1/export' }
            },
            {
              $: { rel: 'move', href: '/api/vms/dfda614f-6b4d-4fe7-a8dc-e8bb636d1df1/move' }
            }
          ]
        },
        status: { state: 'down' },
        cluster: {
          $: { href: '/api/clusters/0fda9d72-7430-11e2-9d4e-3085a99aa783', id: '0fda9d72-7430-11e2-9d4e-3085a99aa783' }
        },
        origin: 'ovirt',
        type: 'desktop',
        display: {
          allow_reconnect: 'false',
          monitors: '1',
          type: 'spice'
        },
        template: {
          $: { href: '/api/templates/00000000-0000-0000-0000-000000000000', id: '00000000-0000-0000-0000-000000000000' }
        },
        usb: { enabled: 'false' },
        os: {
          cmdline: {},
          kernel: {},
          $: { type: 'other_linux' },
          initrd: {},
          boot: {
            $: { dev: 'hd' }
          }
        },
        memory_policy: { guaranteed: '536870912' },
        cpu: {
          topology: {
            $: { cores: '1', sockets: '1' }
          }
        },
        quota: {
          $: { id: '61095ffa-e4ac-4ecc-bbb2-fe48399a410e' }
        },
        placement_policy: { affinity: 'migratable' },
        creation_time: '2013-02-11T13:29:50.976+02:00',
        memory: '1073741824',
        name: 'west-vm',
        high_availability: { enabled: 'false', priority: '1' },
        stateless: 'false'
      }
    ]
  }
}
