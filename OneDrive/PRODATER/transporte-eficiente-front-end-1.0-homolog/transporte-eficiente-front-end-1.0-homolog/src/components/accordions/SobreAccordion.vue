<script setup lang="ts">
import { ref } from 'vue'

type Item = {
  id: string
  title: string
  content: string
}

defineProps<{
  items: Item[]
}>()

const openId = ref<string | null>(null)

function toggle(id: string) {
  openId.value = openId.value === id ? null : id
}
</script>

<template>
  <div class="space-y-3">
    <section
      v-for="it in items"
      :key="it.id"
      class="w-[300px] "
    >
      <!-- Header -->
      <h3 class="m-0 rounded-lg border border-[--color-primary] overflow-hidden bg-white shadow-sm">
        <button
          type="button"
          class="w-full flex items-center justify-between gap-3 px-2 py-2 md:py-2.5 text-left text-xl font-semibold focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[--color-primary]"
          :aria-expanded="openId === it.id ? 'true' : 'false'"
          :aria-controls="`${it.id}-panel`"
          @click="toggle(it.id)"
        >
          <span class="inline-flex items-center gap-2 text-[--color-primary]">
            <i
              class="fas fa-angle-right transition-transform text-[--color-primary]"
              :class="openId === it.id ? 'rotate-90' : ''"
            ></i>
            {{ it.title }}
          </span>
        </button>
      </h3>

      <!-- Painel -->
      <div
        :id="`${it.id}-panel`"
        role="region"
        :aria-labelledby="`${it.id}-header`"
        v-show="openId === it.id"
        class="p-2 text-sm leading-relaxed  text-gray-700  bg-white"
      >
        {{ it.content }}
      </div>
    </section>
  </div>
</template>
