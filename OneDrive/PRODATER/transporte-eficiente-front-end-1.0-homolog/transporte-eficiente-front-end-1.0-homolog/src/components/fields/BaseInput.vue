<script setup lang="ts">
import { Eye, EyeOff } from 'lucide-vue-next'
import { ref, computed } from 'vue'

const props = defineProps({
  id: { type: String, default: '' },
  label: { type: String, default: '' },
  placeholder: { type: String, default: '' },
  required: { type: Boolean, default: false },
  description: { type: String, default: '' },
  type: { type: String, default: 'text' },
  modelValue: { type: String, default: '' },
  disabled: { type: Boolean, default: false },
  icon: { type: [String, Object, Function], default: undefined },
  iconLeft: { type: [String, Object, Function], default: null },
  status: {
    type: String,
    default: '',
    validator: (value: string) => ['', 'success', 'danger', 'info', 'warning'].includes(value),
  },
  message: { type: String, default: '' },
  min: { type: String, default: '' },
  max: { type: String, default: '' },
})

const emit = defineEmits(['update:modelValue', 'focus', 'blur', 'iconClick'])

const modelValueProxy = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
})

const showPassword = ref(false)

const inputType = computed(() => {
  if (props.type !== 'password') return props.type
  return showPassword.value ? 'text' : 'password'
})

function handleIconClick() {
  if (props.type === 'password') {
    showPassword.value = !showPassword.value
  }
  emit('iconClick')
}
</script>

<template>
  <div class="br-input" :class="status">
    <label :for="id" class="flex gap-1">
      <span v-if="required" class="text-red-600 text-xl">*</span>{{ label }}
    </label>
    <div class="input-group">
      <div v-if="iconLeft" class="input-icon ml-2">
        <i
          v-if="typeof iconLeft === 'string'"
          :class="[iconLeft, 'text-sm']"
          aria-hidden="true"
        ></i>
        <component v-else :is="iconLeft" />
      </div>
      <input
        :id="id"
        :type="inputType"
        :placeholder="placeholder"
        :disabled="disabled"
        v-model="modelValueProxy"
        :min="min"
        :max="max"
        :aria-describedby="message ? `${id}-msg` : undefined"
        @focus="$emit('focus')"
        @blur="$emit('blur')"
      />
    </div>
    <button
      v-if="props.type === 'password'"
      class="br-button"
      type="button"
      @click="handleIconClick"
      aria-label="Alternar visibilidade da senha"
      role="switch"
      :aria-checked="showPassword"
    >
      <component :is="showPassword ? EyeOff : Eye" />
    </button>

    <button
      v-else-if="icon"
      class="br-button"
      type="button"
      @click="handleIconClick"
      aria-label="Ícone do input"
    >
      <i v-if="typeof icon === 'string'" :class="icon" aria-hidden="true"></i>
      <component v-else :is="icon" />
    </button>
    <span
      v-if="message"
      class="feedback absolut z-10"
      :class="status"
      role="alert"
      :id="`${id}-msg`"
    >
      <i v-if="status === 'success'" class="fas fa-check-circle" aria-hidden="true"></i>
      <i v-else-if="status === 'danger'" class="fas fa-times-circle" aria-hidden="true"></i>
      <i v-else-if="status === 'info'" class="fas fa-info-circle" aria-hidden="true"></i>
      <i
        v-else-if="status === 'warning'"
        class="fas fa-exclamation-triangle"
        aria-hidden="true"
      ></i>
      {{ message }}
    </span>
    <small v-if="description" class="block text-xs text-gray-500 mt-1">
      {{ description }}
    </small>
  </div>
</template>

<!-- Modo de uso -->

<!--
// Variaveis de input
const nome = ref('')
const email = ref('')
const telefone = ref('')
const cpf = ref('')
const senha = ref('')
const informacao = ref('')
const aviso = ref('')

   //normal
   <BaseInput
      id="nome"
      label="Nome Completo"
      placeholder="Digite seu nome"
      type="text"
      required
      description="Descricao do input"
      v-model="nome"
      icon-left="fas fa-user"
    />

    //com incone e show password
    <BaseInput
      id="senha"
      label="Senha"
      placeholder="Digite sua senha"
      type="password"
      v-model="senha"
    />
    //com incone e lado direito botao
    <BaseInput
      id="senha"
      label="Senha"
      placeholder="Digite sua senha"
      type="text". //tem que ser type text
      v-model="senha"
      :icon="'fas fa-search'"
    />

    //desabilitado
    <BaseInput
     id="cpf"
     label="CPF"
     placeholder="CPF"
     type="text"
     v-model="cpf"
     :disabled="true"
    />

    //com status sucesso
    <BaseInput
      id="telefone"
      label="Telefone"
      type="text"
      v-model="telefone"
      status="success"
      message="Telefone validado com sucesso."
    />

    //com status danger
    <BaseInput
      id="email"
      label="Email"
      type="text"
      v-model="email"
      status="danger"
      message="Email inválido."
    />

    //com status info
    <BaseInput
      id="info"
      label="Informação"
      type="text"
      v-model="informacao"
      status="info"
      message="Apenas números são permitidos."
    />

    //com status warning
    <BaseInput
      id="aviso"
      label="Aviso"
      type="text"
      v-model="aviso"
      status="warning"
      message="Atenção ao preencher."
    />
-->
