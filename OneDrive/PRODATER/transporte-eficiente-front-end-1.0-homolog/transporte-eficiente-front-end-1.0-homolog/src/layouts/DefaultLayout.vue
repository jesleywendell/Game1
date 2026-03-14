<script setup lang="ts">
import SimpleFooter from '@/components/footer/SimpleFooter.vue'
import SimpleHeader from '@/components/header/SimpleHeader.vue'

const props = defineProps<{
  title: string
  logoSrc: string
  links: Array<{ label: string; to?: string; link?: string; icon?: string }>
}>()
</script>

<template>
  <div class="flex min-h-screen w-full flex-col">
    <SimpleHeader :title="props.title" :logoSrc="props.logoSrc" :links="props.links">
      <!-- Passa pro compoenent de uso definir os items do modal flutuante(menu que aparece ao clicar no nome do usuario)-->
      <template #items-modal-float>
        <slot name="items-modal-float" />
      </template>
    </SimpleHeader>

    <main class="px-8 py-2 container-lg flex flex-col flex-1">
      <template v-if="$slots['header-title']">
        <h1 class="m-0 text-xl sm:text-3xl mt-4 sm:!mt-0 mb-4">
          <slot name="header-title" />
        </h1>
      </template>

      <slot></slot>
    </main>

    <SimpleFooter />
  </div>
</template>
