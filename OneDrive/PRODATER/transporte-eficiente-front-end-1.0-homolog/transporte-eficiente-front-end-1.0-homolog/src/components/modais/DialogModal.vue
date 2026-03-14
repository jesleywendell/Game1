<script setup lang="ts">
defineProps({
  show: Boolean,
  title: String,
  titleIcon: {
    type: String,
    default: '',
  },
  confirmText: {
    type: String,
    default: 'Confirmar',
  },
  cancelText: {
    type: String,
    default: 'Cancelar',
  },
  closable: {
    type: Boolean,
    default: true,
  },
  showCancel: {
    type: Boolean,
    default: true,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  loading: {
    type: Boolean,
    default: false,
  },
})
const emit = defineEmits(['confirm', 'close'])

import BaseButton from '@/components/buttons/BaseButton.vue'

function onCloseClick() {
  emit('close')
}
</script>

<template>
  <div
    class="br-modal medium"
    aria-modal="true"
    role="dialog"
    aria-labelledby="dialog-title"
    v-if="show"
  >
    <div class="br-modal-header">
      <div class="modal-title" id="dialog-title">
        <i v-if="titleIcon" :class="titleIcon" class="mr-2 text-[--color-primary]" aria-hidden="true"></i>
        {{ title }}
      </div>
      <button
        v-if="closable"
        class="br-button close circle"
        type="button"
        @click="onCloseClick"
        aria-label="Fechar"
      >
        <i class="fas fa-times" aria-hidden="true"></i>
      </button>
    </div>

    <div class="br-modal-body">
      <slot />
    </div>

    <div class="br-modal-footer justify-content-end">
      <BaseButton
        v-if="showCancel"
        variant="secondary"
        type="button"
        @click="onCloseClick"
      >
        {{ cancelText }}
      </BaseButton>

      <BaseButton
        class="ml-2"
        variant="primary"
        type="button"
        :disabled="disabled"
        :loading="loading"
        @click="$emit('confirm')"
      >
        {{ confirmText }}
      </BaseButton>
    </div>
  </div>
</template>

<!--
//Modelo de uso

//Evento do modal dialog
  const showDialog = ref(false)

 //Botao de abrir o modal dialog
    <BaseButton variant="primary" @click="showDialog = true">Abrir Diálogo</BaseButton>


    <DialogModal
      :show="showDialog"
      confirmText="Confirmar"
      title="Excluir item"
      titleIcon="fas fa-exclamation-triangle"
      :closable="true"
      :showCancel="true"
      :disabled="true"
      :loading="true"
      @close="showDialog = false"
      @confirm="console.log('confirmado')"
    >
      <p class="text-sm">
        Você tem certeza que deseja excluir este item? Esta ação não pode ser desfeita.
      </p>

      <BaseInput id="motivo" label="Motivo" placeholder="Digite motivo" type="text" />
    </DialogModal>

-->
