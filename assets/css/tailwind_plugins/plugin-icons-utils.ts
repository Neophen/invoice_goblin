import { readFileSync, readdirSync } from 'fs'
import { basename, join } from 'path'
import type { KeyValuePair } from 'tailwindcss/types/config'

// Documentation:
// We use mask-image to display the icon.
// This is the default way that phoenix-liveview handles icons.
// We allow to pass a custom stroke-width to the icon.
// For example: "feather-[plus,2]". This is only used in admin, we most likely can remove this
// You can't use class="stroke-2" for example, because it's does not work with mask-image.

// Why?

// First of all, we shouldn't polute server side code with atoms for client side icons.
// It's easier to track usage of icons.
// custom-[something] always means custom icons
// feather-[something] always means feather icons
// using it as a class also allow for easier management of icons with css selectors.
// For example: class="custom-icon data-active:custom-icon-active"

export type Icon = {
  name: string
  fullPath: string
}

export type IconValues = KeyValuePair<string, Icon>

export const getIconValues = (iconsDir: string, transformName?: (name: string) => string) => {
  const values: IconValues = {}

  for (const file of readdirSync(iconsDir)) {
    // Skip non-SVG files
    if (!file.endsWith('.svg')) continue
    const fullName = basename(file, '.svg')
    const name = transformName ? transformName(fullName) : fullName
    values[name] = { name, fullPath: join(iconsDir, file) }
  }

  return values
}

export const getIconCSS = (value: string | Icon, values: IconValues) => {
  let name = ''
  let fullPath = ''
  let strokeWidth = '1.5'

  if (typeof value === 'string') {
    const hasModifier = value.includes(',')
    const iconName = hasModifier ? value.split(',')[0] : value
    const customStrokeWidth = hasModifier ? value.split(',')[1] : '1.5'
    const icon = values[iconName] || {}
    name = iconName
    fullPath = icon.fullPath
    strokeWidth = customStrokeWidth
  } else {
    name = value.name
    fullPath = value.fullPath
  }

  if (!fullPath) {
    return {}
  }

  const content = readFileSync(fullPath)
    .toString()
    .replace(/\r?\n|\r/g, '')
    .replace(/<svg([^>]*)>/g, (_match, attributes: string) => {
      // Remove width and height attributes (with preceding whitespace) from the svg opening tag
      const cleanedAttributes = attributes.replace(/\s+width="[^"]*"/g, '').replace(/\s+height="[^"]*"/g, '')
      return `<svg${cleanedAttributes}>`
    })
    .replace(/\sstroke-width="[^"]*"/, ` stroke-width="${strokeWidth}"`)

  const varName = `--icon-url-${name}`

  return {
    [varName]: `url('data:image/svg+xml;utf8,${content}')`,
    '-webkit-mask': `var(${varName})`,
    mask: `var(${varName})`,
    'mask-repeat': 'no-repeat',
    'background-color': 'currentColor',
    'vertical-align': 'middle',
    'horizontal-align': 'middle',
    display: 'inline-block',
    width: '1.25rem',
    height: '1.25rem'
  }
}
