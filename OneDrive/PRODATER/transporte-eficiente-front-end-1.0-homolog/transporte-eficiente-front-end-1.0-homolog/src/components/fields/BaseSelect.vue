<script setup lang="ts">
import { ref, computed, onMounted, onBeforeUnmount } from 'vue'

const props = defineProps({
  label: String,
  required: {
    type: Boolean,
    default: false,
  },
  description: {
    type: String,
    default: '',
  },
  message: {
    type: String,
    default: '',
  },
  placeholder: {
    type: String,
    default: 'Selecione o item',
  },
  status: {
    type: String as () => '' | 'success' | 'danger' | 'info' | 'warning',
    default: '',
  },
  modelValue: {
    type: [String, Number, Boolean, Array],
    required: true,
  },
  options: {
    type: Array as () => { label: string; value: string | number | boolean }[],
    required: true,
  },
  multiple: {
    type: Boolean,
    default: false,
  },
  icon: {
    type: String,
    default: 'fas fa-search',
  },
  disabled: { type: Boolean, default: false },
})

const emit = defineEmits(['update:modelValue'])

const isOpen = ref(false)
const selectId = `select-${Math.random().toString(36).substr(2, 9)}`

const rootEl = ref<HTMLElement | null>(null)

const handleClickOutside = (e: MouseEvent) => {
  if (rootEl.value && !rootEl.value.contains(e.target as Node)) {
    isOpen.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
})

const searchQuery = ref('')
const filteredOptions = computed(() => {
  const query = searchQuery.value.toLowerCase()
  return props.options.filter((o) => o.label.toLowerCase().includes(query))
})

const displayValue = computed(() => {
  if (isOpen.value || searchQuery.value) return searchQuery.value

  if (props.multiple && Array.isArray(props.modelValue)) {
    const selectedLabels = props.options
      .filter((o) => Array.isArray(props.modelValue) && props.modelValue.includes(o.value))
      .map((o) => o.label)
    return selectedLabels.join(', ')
  }

  const selected = props.options.find((o) => o.value === props.modelValue)
  return selected?.label || ''
})

const onInputChange = (e: Event) => {
  const target = e.target as HTMLInputElement
  searchQuery.value = target.value
}

const toggle = () => {
  isOpen.value = !isOpen.value
}

const isChecked = (value: string | number | boolean) => {
  if (props.multiple && Array.isArray(props.modelValue)) {
    return props.modelValue.includes(value as never)
  }
  return props.modelValue === value
}

const selectOption = (value: string | number | boolean) => {
  if (props.multiple) {
    const current = Array.isArray(props.modelValue) ? [...props.modelValue] : []
    const index = current.indexOf(value)
    if (index > -1) current.splice(index, 1)
    else current.push(value)
    emit('update:modelValue', current)
    searchQuery.value = ''
  } else {
    emit('update:modelValue', value)
    searchQuery.value = ''
    isOpen.value = false
  }
}
</script>

<template>
  <div ref="rootEl" class="w-full" :class="['br-select', { multiple: props.multiple }]">
    <div class="br-input" :class="status">
      <label v-if="label" :for="selectId" class="flex gap-1">
        <span v-if="required" class="text-red-600 text-xl">*</span>{{ label }}
      </label>
      <input
        :id="selectId"
        type="text"
        :disabled="disabled"
        :value="displayValue"
        :placeholder="placeholder"
        @focus="isOpen = true"
        @input="onInputChange"
      />
      <i
        :class="[icon]"
        aria-hidden="true"
        style="position: absolute; left: 5px; top: 70%; transform: translateY(-50%); color: #888"
      />
      <button
        class="br-button"
        type="button"
        :disabled="disabled"
        aria-label="Exibir lista"
        tabindex="-1"
        @click="toggle"
      >
        <i class="fas fa-angle-down" aria-hidden="true"></i>
      </button>
    </div>

    <div v-if="isOpen" class="br-list" tabindex="0">
      <div v-for="(option, index) in filteredOptions" :key="index" class="br-item" tabindex="-1">
        <div :class="multiple ? 'br-checkbox' : 'br-radio'">
          <input
            :id="`${selectId}-${index}`"
            :type="multiple ? 'checkbox' : 'radio'"
            :name="selectId"
            :value="option.value"
            :checked="isChecked(option.value)"
            @change="selectOption(option.value)"
          />
          <label :for="`${selectId}-${index}`">{{ option.label }}</label>
        </div>
      </div>
    </div>
    <template v-if="message">
      <span class="feedback danger" role="alert">
        <i class="fas fa-times-circle" aria-hidden="true"></i>
        {{ message }}
      </span>
    </template>
    <small v-if="description" class="block text-xs text-gray-500 mt-1">
      {{ description }}
    </small>
    <slot name="feedback" v-else />
  </div>
</template>

<style>
.br-list {
  display: block !important;
  background: white;
  border: 1px solid #ccc;
  position: absolute;
  width: 100%;
  z-index: 10;
  max-height: 200px;
  overflow-y: auto;
  border-radius: 4px;
  box-shadow: 0 0 0.5rem rgba(0, 0, 0, 0.1);
}

.br-item {
  padding: 0.5rem 1rem;
  cursor: pointer;
}

.br-item:hover {
  background-color: #e8f1ff;
}

.br-select {
  position: relative;
}

.br-input {
  position: relative;
}

.br-input input {
  padding-left: 2rem !important;
}
</style>

<!--
modelos de uso

    <BaseSelect label="Estado" v-model="estado" :options="estados" />

    <BaseSelect label="Estados" v-model="estadosSelecionados" :options="estados" multiple />

    <BaseSelect
      label="Estado"
      v-model="estado"
      :options="estados"
      status="danger"
      message="Campo obrigatório"
    />
-->
