<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps({
  variant: {
    type: String as () => 'primary' | 'secondary' | 'tertiary',
    default: 'primary',
  },
  size: {
    type: String as () => 'small' | 'medium' | 'large',
    default: 'medium',
  },
  icon: {
    type: [String, Object, Function],
    default: '',
  },
  iconColor: {
  type: String,
  default: '',
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

const buttonClasses = computed(() => [
  'br-button',
  props.variant === 'primary' ? 'primary' : props.variant === 'secondary' ? 'secondary' : '',
  props.variant === 'tertiary' ? 'bg-white' : '',
  props.size === 'small' ? 'small' : '',
  props.size === 'large' ? 'large' : '',
  props.icon ? 'has-icon' : '',
  props.loading ? 'loading' : '',
])
</script>

<template>
  <button :class="buttonClasses" :disabled="disabled">
    <span v-if="icon && !loading" class="icon">
      <component :is="icon" class="w-4 h-4 mr-1" />
    </span>
    <slot />
  </button>
</template>
