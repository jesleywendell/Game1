<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from 'vue'

interface MenuItem {
  label: string
  icon?: string
  to?: string
  link?: string
  children?: MenuItem[]
}

const resolveTo = (item: MenuItem) => item.to || item.link || '#'

defineProps<{
  menuItems: MenuItem[]
}>()

const submenuAberto = ref<string | null>(null)

const emit = defineEmits(['close'])

const fecharMenu = () => {
  emit('close')
}

const handleClickFora = (event: MouseEvent) => {
  const menu = document.querySelector('.br-menu')
  if (menu && !menu.contains(event.target as Node)) {
    fecharMenu()
  }
}

onMounted(() => {
  // Evitar que o menu feche logo apos aberto
  setTimeout(() => {
    document.addEventListener('click', handleClickFora)
  }, 100)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickFora)
})
</script>

<template>
  <div class="fixed top-0 left-0 z-50 flex w-full h-full bg-black bg-opacity-50">
    <div class="flex flex-col w-[280px] h-full bg-white shadow-lg br-menu">
      <div class="flex items-center justify-between border-b menu-header">
        <div class="flex flex-col items-center justify-center">
          <img src="/imgs/LOGO_PMT_25.jpg" alt="Logo" class="h-20 w-100" />
          <!-- <span class="font-bold">Transporte Eficiente</span> -->
        </div>
        <button
          class="br-button circle"
          type="button"
          aria-label="Fechar o menu"
          @click="$emit('close')"
        >
          <i class="fas fa-times"></i>
        </button>
      </div>

      <nav class="flex-1 overflow-y-auto menu-body">
        <ul class="text-blue-700">
          <li
            v-for="item in menuItems"
            :key="item.label"
            class="border-b border-gray-200"
          >
            <template v-if="item.children">
              <div>
                <div
                  class="flex items-center justify-between w-full cursor-pointer br-item menu-item text-blue-700 hover:bg-[#E8EDF3] pl-3 pr-4 rounded-md"
                  @click="submenuAberto = submenuAberto === item.label ? null : item.label"
                >
                  <div class="flex items-center space-x-2">
                    <i :class="item.icon"></i>
                    <span class="text-base font-medium">{{ item.label }}</span>
                  </div>
                  <div class="ml-auto">
                    <i
                      :class="
                        submenuAberto === item.label ? 'fas fa-chevron-down' : 'fas fa-chevron-right'
                      "
                    ></i>
                  </div>
                </div>
                <ul
                  v-show="submenuAberto === item.label"
                  class="space-y-1 bg-gray-100"
                >
                  <li
                    v-for="child in item.children"
                    :key="child.label"
                    class="border-b border-gray-200"
                  >
                    <component
                      :is="child.link ? 'a' : 'RouterLink'"
                      :to="child.link ? undefined : resolveTo(child)"
                      :href="child.link ? child.link : undefined"
                      v-bind="child.link ? { target: '_blank', rel: 'noopener' } : {}"
                      class="flex items-center text-blue-700 hover:bg-[#E8EDF3] px-6 py-3 w-full"
                    >
                      {{ child.label }}
                    </component>
                  </li>
                </ul>
              </div>
            </template>

            <template v-else>
              <component
                :is="item.link ? 'a' : 'RouterLink'"
                :to="item.link ? undefined : resolveTo(item)"
                :href="item.link ? item.link : undefined"
                v-bind="item.link ? { target: '_blank', rel: 'noopener' } : {}"
                class="flex items-center p-3 space-x-2 br-item"
              >
                <i :class="item.icon"></i>
                <span class="text-base font-medium">{{ item.label }}</span>
              </component>
            </template>
          </li>
        </ul>
      </nav>

      <div class="px-4 py-3 border-t border-gray-200 menu-footer">
        <div class="flex space-x-2">
          <a
            href="https://facebook.com"
            target="_blank"
            class="br-button circle small"
            aria-label="Facebook"
          >
            <i class="fab fa-facebook-f"></i>
          </a>
          <a
            href="https://instagram.com"
            target="_blank"
            class="br-button circle small"
            aria-label="Instagram"
          >
            <i class="fab fa-instagram"></i>
          </a>
          <a
            href="https://linkedin.com"
            target="_blank"
            class="br-button circle small"
            aria-label="Linkedin"
          >
            <i class="fab fa-linkedin"></i>
          </a>
        </div>
      </div>
    </div>
  </div>
</template>

<!-- Modelo de uso -->

<!--
const menuAberto = ref(false)

const toggleMenu = () => {
  menuAberto.value = true
}


  //Botão para abrir o menu mobile
    <button
      class="br-button small circle"
      type="button"
      aria-label="Menu"
      @click="
        () => {
          toggleMenu()
        }
      "
    >
      <i class="fas fa-bars" aria-hidden="true"></i>
    </button>

    //Renderização do menu
    <MenuMobile
      v-if="menuAberto"
      @close="menuAberto = false"
      :menuItems="[
        {
          label: 'Início',
          icon: 'fas fa-home',
          to: '/',
        },
        {
          label: 'Saúde',
          icon: 'fas fa-heart',
          children: [
            { label: 'Consulta', to: '/consulta' },
            { label: 'Agendamento', to: '/agendamento' },
          ],
        },
        {
          label: 'Serviços',
          icon: 'fas fa-database',
          children: [
            { label: 'Solicitar', to: '/solicitar' },
            { label: 'Agendar', to: '/agendar' },
          ],
        },
        {
          label: 'Configurações',
          icon: 'fas fa-cog',
          link: '/configuracoes',
        },
        {
          label: 'Fale Conosco',
          icon: 'fas fa-envelope',
          link: '/contato',
        },
      ]"
    />
-->
