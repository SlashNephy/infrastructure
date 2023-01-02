import { exec } from 'child_process'
import { readdirSync } from 'fs'
import { readdir } from 'fs/promises'
import { join } from 'path'
import { promisify } from 'util'

export const buildManifest = async (
  path: string
): Promise<{ stdout: string; stderr: string }> => {
  const execAsync = promisify(exec)
  return await execAsync(`kustomize build --enable-helm ${path}`, {
    maxBuffer: 1024 * 1024 * 10,
  })
}

export type File = {
  path: string
  filename: string
  directory: string
}

// eslint-disable-next-line @typescript-eslint/naming-convention
async function* enumerateFiles(directory: string): AsyncGenerator<File> {
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      yield* enumerateFiles(join(directory, entry.name))
    } else if (entry.isFile()) {
      yield {
        path: join(directory, entry.name),
        filename: entry.name,
        directory,
      }
    }
  }
}

export const globFiles = async (
  directory: string,
  pattern: RegExp
): Promise<File[]> => {
  const files: File[] = []
  for await (const file of enumerateFiles(directory)) {
    if (pattern.test(file.filename)) {
      files.push(file)
    }
  }
  return files
}

// jest で Promise の解決が面倒くさいので...
// https://github.com/facebook/jest/issues/2235
// https://kulshekhar.github.io/ts-jest/docs/guides/esm-support/
// eslint-disable-next-line @typescript-eslint/naming-convention
function* enumerateFilesSync(directory: string): Generator<File> {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      yield* enumerateFilesSync(join(directory, entry.name))
    } else if (entry.isFile()) {
      yield {
        path: join(directory, entry.name),
        filename: entry.name,
        directory,
      }
    }
  }
}

export const globFilesSync = (directory: string, pattern: RegExp): File[] => {
  const files: File[] = []
  for (const file of enumerateFilesSync(directory)) {
    if (pattern.test(file.filename)) {
      files.push(file)
    }
  }
  return files
}
