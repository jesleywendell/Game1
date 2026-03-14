import './assets/main.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'

// Importação GovBR Design System
import '@govbr-ds/core/dist/core.min.css'
import '@fortawesome/fontawesome-free/css/fontawesome.min.css'
import '@fortawesome/fontawesome-free/css/solid.min.css'
import '@fortawesome/fontawesome-free/css/regular.min.css'

// imoportação leaflet
import 'leaflet/dist/leaflet.css'
import 'leaflet/dist/leaflet.js'

import { VueQueryPlugin, type VueQueryPluginOptions } from '@tanstack/vue-query'

const app = createApp(App)

const vueQueryOptions: VueQueryPluginOptions = {
  queryClientConfig: {
    defaultOptions: {
      queries: {
        refetchOnWindowFocus: false,
      },
    },
  },
}

app.use(createPinia())
app.use(router)
app.use(VueQueryPlugin, vueQueryOptions)

app.mount('#app')
