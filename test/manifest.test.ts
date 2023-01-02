import assert from 'assert'
import { resolve } from 'path'

import { buildManifest, globFilesSync } from './lib'

describe('manifests', () => {
  const manifests = globFilesSync(
    resolve(__dirname, '..'),
    /kustomization\.ya?ml$/
  )

  for (const manifest of manifests) {
    test(
      `${manifest.directory} matches snapshot`,
      async () => {
        const result = await buildManifest(manifest.directory)

        assert.equal(result.stderr, '')
        expect(result.stdout).toMatchSnapshot()
      },
      30 * 1000
    )
  }
})
