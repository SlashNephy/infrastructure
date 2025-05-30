import { config } from '@slashnephy/eslint-config'
import { globalIgnores } from 'eslint/config'

export default config(
  {},
  globalIgnores(['**/charts/**']),
  {
    files: ['k8s/**/*.yml'],
    rules: {
      'yml/sort-keys': [
        'error',
        {
          pathPattern: '^$',
          order: [
            'apiVersion',
            'kind',
            'metadata',
            'namespace',
            'type',
            'spec',
            'images',
            'helmCharts',
            'commonLabels',
            'resources',
            'configMapGenerator',
            'patchesStrategicMerge',
            'patchesJson6902',
            {
              order: {
                type: 'asc',
              },
            },
          ],
        },
        {
          pathPattern: '^metadata$',
          order: [
            'name',
            'namespace',
            'annotations',
            {
              order: {
                type: 'asc',
              },
            },
          ],
        },
        {
          pathPattern: '^rules\\[\\d+\\]$',
          order: [
            'apiGroups',
            'resources',
            'resourceNames',
            'verbs',
            {
              order: {
                type: 'asc',
              },
            },
          ],
        },
        {
          pathPattern: '^images\\[\\d+\\]$',
          order: [
            'name',
            'newName',
            'newTag',
            'digest',
            {
              order: {
                type: 'asc',
              },
            },
          ],
        },
        {
          pathPattern: '^helmCharts\\[\\d+\\]$',
          order: [
            'name',
            'releaseName',
            'namespace',
            'version',
            'repo',
            'includeCRDs',
            'valuesFile',
            'valuesInline',
            {
              order: {
                type: 'asc',
              },
            },
          ],
        },
        {
          pathPattern: '^spec$',
          order: [
            'replicas',
            'strategy',
            'selector',
            'schedule',
            'timeZone',
            'type',
            'generators',
            'template',
            'jobTemplate',
            'ports',
            'storageClassName',
            {
              order: {
                type: 'asc',
              },
            },
          ],
        },
        {
          pathPattern: '^spec\\.routes\\[\\d+\\]$',
          order: [
            'kind',
            'match',
            'priority',
            'services',
            'middlewares',
            {
              order: {
                type: 'asc',
              },
            },
          ],
        },
        {
          pathPattern: '^spec\\.ports\\[\\d+\\]$',
          order: [
            'name',
            'port',
            'targetPort',
            'nodePort',
            'prorocol',
            {
              order: {
                type: 'asc',
              },
            },
          ],
        },
        {
          pathPattern: '^(spec|spec\\.jobTemplate\\.spec)\\.template$',
          order: [
            'metadata',
            'spec',
            {
              order: {
                type: 'asc',
              },
            },
          ],
        },
        {
          pathPattern: '^(spec|spec\\.jobTemplate\\.spec)\\.template\\.spec$',
          order: [
            'containers',
            'volumes',
            'restartPolicy',
            {
              order: {
                type: 'asc',
              },
            },
          ],
        },
        {
          pathPattern: '^(spec|spec\\.jobTemplate\\.spec)\\.template\\.spec\\.containers\\[\\d+\\]$',
          order: [
            'name',
            'image',
            'imagePullPolicy',
            'workingDir',
            'command',
            'args',
            'env',
            'envFrom',
            'ports',
            'volumeMounts',
            'resources',
            {
              order: {
                type: 'asc',
              },
            },
          ],
        },
        {
          pathPattern: '^(spec|spec\\.jobTemplate\\.spec)\\.template\\.spec\\.containers\\[\\d+\\]\\.volumeMounts\\[\\d+\\]$',
          order: [
            'name',
            'mountPath',
            'readonly',
            {
              order: {
                type: 'asc',
              },
            },
          ],
        },
        {
          pathPattern: '^(spec|spec\\.jobTemplate\\.spec)\\.template\\.spec\\.volumes\\[\\d+\\]$',
          order: [
            'name',
            'hostPath',
            {
              order: {
                type: 'asc',
              },
            },
          ],
        },
        {
          pathPattern: '^(spec|spec\\.jobTemplate\\.spec)\\.template\\.spec\\.volumes\\[\\d+\\]\\.hostPath$',
          order: [
            'path',
            'type',
            {
              order: {
                type: 'asc',
              },
            },
          ],
        },
        {
          pathPattern: '^patches\\[\\d+\\]$',
          order: [
            'path',
            'target',
            'patch',
            {
              order: {
                type: 'asc',
              },
            },
          ],
        },
        {
          pathPattern: '^patches\\[\\d+\\]\\.target$',
          order: [
            'group',
            'version',
            'kind',
            'name',
            {
              order: {
                type: 'asc',
              },
            },
          ],
        },
        {
          pathPattern: '^.+$',
          order: [
            'name',
            {
              order: {
                type: 'asc',
              },
            },
          ],
        },
      ],
      'yml/file-extension': [
        'error',
        {
          extension: 'yaml',
          caseSensitive: true,
        },
      ],
    },
  },
  {
    files: ['k8s/**/config/**/*.yml'],
    rules: {
      'yml/file-extension': 'off',
    },
  },
  {
    rules: {
      'n/no-unpublished-import': 'off',
    },
  },
)
