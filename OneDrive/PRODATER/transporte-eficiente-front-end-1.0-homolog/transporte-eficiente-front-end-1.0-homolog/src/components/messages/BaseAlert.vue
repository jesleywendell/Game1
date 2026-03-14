<script setup lang="ts">
import { onMounted } from 'vue'

const props = defineProps({
  status: {
    type: String,
    default: '',
    validator: (v: string) => ['', 'success', 'danger', 'info', 'warning'].includes(v),
  },
  message: { type: String, required: true },
  showIcon: { type: Boolean, default: true },
  id: { type: String, default: '' },
})

const emit = defineEmits<{
  (e: 'close'): void
}>()

// Mapeia status para ícone FontAwesome
const iconClass =
  {
    success: 'fas fa-check-circle fa-lg',
    danger: 'fas fa-times-circle fa-lg',
    info: 'fas fa-info-circle fa-lg',
    warning: 'fas fa-exclamation-triangle fa-lg',
  }[props.status] || ''

onMounted(() => {
  setTimeout(() => {
    emit('close')
  }, 8000)
})
</script>

<template>
  <div
    class="fixed z-50 flex items-center gap-2 p-3 top-4 right-4 br-message"
    :class="status"
    role="alert"
    :aria-describedby="id || undefined"
  >
    <div class="icon">
      <i v-if="showIcon && iconClass" :class="iconClass" aria-hidden="true"></i>
    </div>
    <span class="message-body">{{ message }}</span>

    <div class="ml-auto close">
      <button
        type="button"
        class="br-button circle small"
        aria-label="Fechar"
        @click="emit('close')"
      >
        <i class="fas fa-times" aria-hidden="true"></i>
      </button>
    </div>
  </div>
</template>

<!-- modelo de uso -->
<!--
  Props:
  - status: '', 'success', 'danger', 'info', 'warning'
  - message: o texto a ser exibido
  - showIcon: controla se o ícone deve aparecer
  - id: opcional, para aria-describedby

  <BaseAlert
    v-if="showSuccess"
    status="success"
    message="Operação realizada com sucesso!"
    @close="showSuccess = false"
  />
  -->
