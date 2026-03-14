<script setup lang="ts">
defineProps<{ cols?: number }>()
</script>

<template>
  <div
    class="grid gap-4"
    :class="{
      'grid-cols-1 sm:grid-cols-1': cols === 1,
      'grid-cols-1 sm:grid-cols-2': cols === 2,
      'grid-cols-1 sm:grid-cols-3': cols === 3,
      'grid-cols-1 sm:grid-cols-4': cols === 4,
    }"
  >
    <slot />
  </div>
</template>

<!--
modelo de uso
  <FormGrid :cols="2"> //col-span-full pra ocupar toda linha

  </FormGrid>
-->
