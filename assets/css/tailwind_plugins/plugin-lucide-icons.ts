import plugin from 'tailwindcss/plugin'
import { getIconValues, getIconCSS } from './plugin-icons-utils'
import { join } from 'path'
import type { IconValues, Icon } from './plugin-icons-utils'

// Example
// <div class="lucide-settings">⚙︎</div>

/* eslint-disable @typescript-eslint/unbound-method */
export default plugin(({ matchComponents }) => {
  const path = join(__dirname, "../../../deps/lucide_icons/icons")
  const values: IconValues = getIconValues(path)

  matchComponents({ lucide: (value: string | Icon) => getIconCSS(value, values) }, { values })
})
