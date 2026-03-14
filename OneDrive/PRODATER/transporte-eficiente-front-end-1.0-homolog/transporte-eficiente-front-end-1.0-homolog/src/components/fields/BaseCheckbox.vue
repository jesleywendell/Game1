<script setup lang="ts">
import { computed, useAttrs } from 'vue'

const props = defineProps({
  id: { type: String, default: '' },
  name: { type: String, default: '' },
  label: { type: String, default: '' },
  modelValue: { type: Boolean, default: false },
  disabled: { type: Boolean, default: false },
  value: { type: [String, Boolean], default: true },
  status: {
    type: String,
    default: '',
    validator: (value: string) => ['', 'success', 'danger', 'info', 'warning'].includes(value),
  },
  hint: { type: String, default: '' },
})

const attrs = useAttrs()

const emit = defineEmits(['update:modelValue', 'change'])

const modelValueProxy = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
})
</script>

<template>
  <div class="flex flex-col gap-1">
    <div class="br-checkbox" :class="status">
      <input
        :id="id"
        :name="name"
        type="checkbox"
        :disabled="disabled"
        :value="value"
        v-model="modelValueProxy"
        @change="$emit('change', modelValueProxy)"
      />
      <label :for="id" v-bind="attrs">{{ label }}</label>
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
// Variaveis de checkbox
const checked = ref(false)
const checkedDefault = ref(true)
const checkedDisabled = ref(false)
const checkedSuccess = ref(false)
const checkedError = ref(false)
const checkedInfo = ref(false)
const checkedWarning = ref(false)

    // Chheckbox normal
    BaseCheckbox
     id="aceito"
     label="Aceito os termos de uso"
     v-model="checked"
    />

    // Checkbox com valor padrão selecionado
    <BaseCheckbox
      id="noticias"
      label="Quero receber novidades"
      v-model="checkedDefault"
      :value="true"
    />

    // Checkbox desabilitado
    <BaseCheckbox
      id="desabilitado"
      label="Opção desabilitada"
      v-model="checkedDisabled"
      :disabled="true"
    />

    // Checkbox com status de sucesso/success
    <BaseCheckbox
      id="confirmado"
      label="Cadastro confirmado"
      v-model="checkedSuccess"
      status="success"
      hint="Tudo certo!"
    />

    // Checkbox com status de erro/danger
    <BaseCheckbox
      id="erro"
      label="Precisa aceitar"
      v-model="checkedError"
      status="danger"
      hint="Você deve marcar esta opção."
    />

    // Checkbox com status de informação/info
    <BaseCheckbox
      id="informativo"
      label="Informativo"
      v-model="checkedInfo"
      status="info"
      hint="Isso é apenas uma informação."
    />

    // Checkbox com status de aviso/warning
    <BaseCheckbox
      id="atencao"
      label="Atenção"
      v-model="checkedWarning"
      status="warning"
      hint="Cuidado ao selecionar esta opção."
    />
-->
