<script setup lang="ts">
import { computed} from 'vue'

const props = defineProps({
  id: { type: String, required: true },
  label: { type: String, default: '' },
  modelValue: { type: Boolean, default: false },
  disabled: { type: Boolean, default: false },
  status: {
    type: String,
    default: '',
    validator: (value: string) => ['', 'success', 'danger', 'info', 'warning'].includes(value),
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
    <div class="br-switch" :class="status">
      <input
        :id="id"
        type="checkbox"
        :disabled="disabled"
        v-model="modelValueProxy"
        @change="$emit('change', modelValueProxy)"
      />
      <label :for="id">{{ label }}</label>
    </div>
    <div v-if="hint" class="mt-1">
      <span class="feedback" :class="status" role="alert" :id="`${id}-hint`">
        <i v-if="status === 'success'" class="fas fa-check-circle" aria-hidden="true"></i>
        <i v-else-if="status === 'danger'" class="fas fa-times-circle" aria-hidden="true"></i>
        <i v-else-if="status === 'info'" class="fas fa-info-circle" aria-hidden="true"></i>
        <i
          v-else-if="status === 'warning'"
          class="fas fa-exclamation-triangle"
          aria-hidden="true"
        ></i>
        {{ hint }}
      </span>
    </div>
  </div>
</template>

<!-- Modelo de uso -->

<!--
// Variavel de switch
const switchAtivo = ref(false)

    <BaseSwitch
      id="switch1"
      label="Ativar notificações"
      v-model="switchAtivo"
      status="info"
      hint="Você pode ativar ou desativar quando quiser."
    />

-->
