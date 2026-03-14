<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps({
  id: { type: String, required: true },
  name: { type: String, required: true },
  label: { type: String, default: '' },
  modelValue: { type: [String, Number, Boolean], default: '' },
  value: { type: [String, Number, Boolean], required: true },
  disabled: { type: Boolean, default: false },
  status: {
    type: String,
    default: '',
    validator: (value: string) =>
      ['', 'success', 'danger', 'info', 'warning'].includes(value),
  },
  hint: { type: String, default: '' },
})

const emit = defineEmits(['update:modelValue', 'change'])

const modelValueProxy = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
})
</script>

<template>
  <div class="flex flex-col gap-1">
    <div class="br-radio" :class="status">
      <input
        type="radio"
        :id="id"
        :name="name"
        :value="value"
        :disabled="disabled"
        :checked="modelValue === value"
        @change="modelValueProxy = value"
      />
      <label :for="id">{{ label }}</label>
    </div>
    <div v-if="hint" class="mt-1">
      <span
        class="feedback"
        :class="status"
        role="alert"
        :id="`${id}-hint`"
      >
        <i v-if="status === 'success'" class="fas fa-check-circle" aria-hidden="true"></i>
        <i v-else-if="status === 'danger'" class="fas fa-times-circle" aria-hidden="true"></i>
        <i v-else-if="status === 'info'" class="fas fa-info-circle" aria-hidden="true"></i>
        <i v-else-if="status === 'warning'" class="fas fa-exclamation-triangle" aria-hidden="true"></i>
        {{ hint }}
      </span>
    </div>
  </div>
</template>


<!-- Modelo de uso -->

<!--
// variavel de radio
const radioSelecionado = ref('')

    // Radio Buttons normal
    <BaseRadio
     id="opcao1"
     name="grupo1"
     label="Opção 1"
     :value="'1'"
     v-model="radioSelecionado"
    />

    // Radio Buttons com status e hint exemplo danger
    <BaseRadio
      id="opcao2"
      name="grupo1"
      label="Opção 2"
      :value="'2'"
      v-model="radioSelecionado"
      status="danger"
      hint="Mensagem genérica."
    />

-->
