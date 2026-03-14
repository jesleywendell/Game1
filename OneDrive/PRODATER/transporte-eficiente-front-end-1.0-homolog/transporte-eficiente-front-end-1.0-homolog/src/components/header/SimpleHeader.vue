<script setup lang="ts">
import { ref, computed } from 'vue'
import { RouterLink } from 'vue-router'
import { useUserStore } from '@/stores/user'
import { useAuth } from '@/composables/auth/useAuth'
import MenuMobile from '../menus/MenuMobile.vue'
import MenuFloat from '../menus/MenuFloat.vue'
import BaseButton from '../buttons/BaseButton.vue'
import LoginForm from '../forms/LoginForm.vue'

interface Link {
  label: string
  icon?: string
  to?: string
  link?: string
}

const props = defineProps<{
  links: Link[]
  title: string
  logoSrc: string
}>()

const auth = useAuth()
const userStore = useUserStore()
const isLogged = computed(() => !!userStore.user?.sub)

// Links do header - Logado: links da view + Sobre (Home)
const displayedLinks = computed<Link[]>(() => {
  if (isLogged.value) {
    const sobre: Link = { label: 'Sobre', to: '/', icon: 'fas fa-info-circle' }
    return [...(props.links ?? []), sobre]
  }
  return []
})

const menuAberto = ref(false)
const toggleMenu = () => {
  menuAberto.value = true
}
</script>

<template>
  <header class="bg-white shadow-md px-4 sm:px-8 py-4 flex items-center justify-between">
    <div class="flex items-center gap-4 flex-1">
      <img :src="logoSrc" alt="Logo" class="h-7 md:h-10" />
      <h1
        class="text-xl font-semibold text-gray-800 hidden sm:block m-0 border-l border-gray-300 pl-3"
      >
        {{ title }}
      </h1>
    </div>

    <!-- Navegação desktop -->
    <nav
      v-if="displayedLinks.length"
      class="hidden md:flex items-center gap-6 text-blue-700 font-medium border-r border-gray-300 pr-4"
    >
      <template v-for="(link, index) in displayedLinks" :key="index">
        <RouterLink v-if="link.to" :to="link.to">{{ link.label }}</RouterLink>
        <a
          v-else-if="link.link"
          :href="link.link"
          target="_blank"
          rel="noopener noreferrer"
          class="hover:underline"
        >
          {{ link.label }}
        </a>
      </template>
    </nav>

    <!-- Menu de usuário desktop -->
    <div v-if="isLogged">
      <MenuFloat size="sm" position="top-right">
        <template #trigger="{ toggle }">
          <button
            @click="toggle"
            class="flex items-center gap-2 bg-gray-100 px-2 py-1 ml-4 rounded-xl"
          >
            <div
              class="bg-[--color-primary] text-white rounded-full w-6 h-6 flex items-center justify-center text-sm font-bold"
            >
              <!-- {{ userStore.user?.name?.t(0).toUpperCase() || 'U' }} -->
              {{ userStore.user?.sub?.charAt(0).toUpperCase() || 'U' }}
            </div>
            <span class="text-sm text-gray-800 font-medium">
              <!-- Olá, <span class="font-bold">{{ userStore.user?.name || 'Usuário' }}</span> -->
              Olá, <span class="font-bold">{{ userStore.user?.exp || 'Usuário' }}</span>
              <i class="fas fa-angle-down ml-1"></i>
            </span>
          </button>
        </template>
        <div>
          <!-- Botões adicionais definidos na view -->
          <slot name="items-modal-float" />

          <!-- Botões fixos de deslogar -->
          <button
            class="block w-full text-left px-4 py-3 text-gray-800 border-b border-gray-300 hover:bg-gray-100 cursor-pointer"
            @click="auth.logout()"
          >
            Sair
          </button>
        </div>
      </MenuFloat>
    </div>

    <!-- Botão de expandir modal de login -->
    <div v-else class="border-l border-gray-300 pl-4">
      <MenuFloat size="md" position="top2-right">
        <template #trigger="{ toggle }">
          <BaseButton variant="primary" @click="toggle">
            <i class="fas fa-user mr-1"></i>Entrar
          </BaseButton>
        </template>
        <LoginForm />
      </MenuFloat>
    </div>

    <!-- Botão para abrir o menu mobile -->
    <div v-if="displayedLinks.length">
      <button
        class="md:hidden br-button small circle"
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
    </div>

    <MenuMobile
      v-if="menuAberto"
      @close="menuAberto = false"
      :menuItems="
        displayedLinks.map((link) => ({
          label: link.label,
          icon: link.icon || 'fas fa-angle-right',
          to: link.to,
          link: link.link,
        }))
      "
    />
  </header>
</template>

<!--
modelo de uso
    <SimpleHeader
      title="Transporte Eficiente"
      logoSrc="/imgs/LOGO_PMT_Colorida.svg"
      :links="[
        { label: 'Título I', to: '/playground', icon: 'fas fa-home' },
        { label: 'Título II', to: '/pagina2', icon: 'fas fa-user' },
        { label: 'Título III', to: '/pagina3', icon: 'fas fa-users' },
        { label: 'Site Externo', link: 'https://www.gov.br/ds/home', icon: 'fas fa-external-link-alt' },
      ]"
    />

    //Items do modal flutuante
        <template #items-modal-float>
          <button
            class="block w-full text-left px-4 py-3 text-gray-800 border-b border-gray-300 hover:bg-gray-100 cursor-pointer"
            @click="console.log('Cadastro')"
          >
            Cadastro
          </button>
        </template>
-->
