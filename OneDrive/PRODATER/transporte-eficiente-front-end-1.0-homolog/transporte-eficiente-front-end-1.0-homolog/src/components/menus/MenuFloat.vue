<script setup lang="ts">
import { ref, computed } from 'vue'

const props = defineProps<{
  size?: 'sm' | 'md' | 'lg'
  position?: 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right' |'top2-right'
}>()

const sizeClass = computed(() => {
  return {
    sm: 'w-48',
    md: 'w-76',
    lg: 'w-96',
  }[props.size || 'md']
})

const positionClass = computed(() => {
  return {
    'top2-right': 'top-16 -right-5',
    'top-left': 'top-10 left-0',
    'top-right': 'top-10 right-0',
    'bottom-left': 'bottom-10 left-0',
    'bottom-right': 'bottom-10 right-0',
  }[props.position || 'bottom-right']
})
const isOpen = ref(false)

function toggleMenu() {
  isOpen.value = !isOpen.value
}
</script>

<template>
  <div class="relative inline-block">
    <slot name="trigger" :toggle="toggleMenu"></slot>
    <div
      v-if="isOpen"
      class="absolute z-20 bg-white border border-gray-300 rounded shadow-lg"
      :class="[sizeClass, positionClass]"
    >
      <slot />
    </div>
    <div v-if="isOpen" class="fixed inset-0 z-10" @click="toggleMenu" tabindex="0"></div>
  </div>
</template>

<!--
modelo de uso

<FloatModal size="sm" position="top-left">
      <template #trigger="{ toggle }">
        <button @click="toggle" class="flex items-center gap-2 bg-gray-100 px-3 py-1 rounded-xl">
          Abrir Modal float
        </button>
      </template>

      <template #default>
        <RouterLink
          to="/"
          class="block px-4 py-3 text-gray-800 border-b border-gray-300 hover:bg-gray-100 cursor-pointer"
        >
          Home
        </RouterLink>
        <button
          class="block w-full text-left px-4 py-3 text-gray-800 border-b border-gray-300 hover:bg-gray-100 cursor-pointer"
          @click="console.log('Sair')"
        >
          Sair
        </button>
        <a
          class="block w-full text-left px-4 py-3 text-gray-800 border-b border-gray-300 hover:bg-gray-100 cursor-pointer"
          href="https://google.com.br"
        >
          Externo
        </a>
      </template>
    </FloatModal>


      passanbdo pra o compoenen t final definir os items
      <FloatModal>
        <template #trigger="{ toggle }">
          <button @click="toggle" class="flex items-center gap-2 bg-gray-100 px-3 py-1 rounded-xl">
            <div
              class="bg-blue-700 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm font-bold"
            >
              U
            </div>
            <span class="text-sm text-gray-800 font-medium">
              Olá, <span class="font-bold">Usuário</span>
              <i class="fas fa-angle-down ml-1"></i>
            </span>
          </button>
        </template>
        <slot name="items-modal-float" />  // passa pro compoenent final definir os items
      </FloatModal>

-->
