<script setup lang="ts">
import { ref } from 'vue'

defineProps<{
  title: string
}>()

const isOpen = ref(true)
const toggle = () => (isOpen.value = !isOpen.value)
</script>

<template>
  <div class="bg-transparent">
    <div class="flex items-center py-2 mt-4 cursor-pointer font-semibold" @click="toggle">
      <span class="text-base">{{ title }}</span>
      <i
        :class="isOpen ? 'fas fa-chevron-up' : 'fas fa-chevron-down'"
        class="text-gray-600 ml-2"
      ></i>
    </div>

    <div v-show="isOpen" class="p-4 bg-gray-3">
      <slot />
    </div>
  </div>
</template>

<!--
modelo de uso
      <form>
        <AcordionCard title="Dados Pessoais">
          <BaseInput label="Nome Completo" type="text" placeholder="Digite o nome completo" />
          <BaseInput label="CPF" type="text" />
          <BaseInput label="Data de Nascimento" type="text" />

        </AcordionCard>

        <AcordionCard title="Informações de Responsável">
          <BaseInput label="Tutor Responsável" type="text" />
          <BaseInput label="Nome Completo" type="text" placeholder="Digite o nome completo" />

        </AcordionCard>

        <AcordionCard title="Situação e Observações">
          <BaseInput label="Nome Completo" type="text" placeholder="Digite o nome completo" />
          <BaseInput label="Observações" type="textarea" />
        </AcordionCard>
      </form>
-->
