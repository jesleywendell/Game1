<!-- src/components/buttons/BottomSheet.vue -->
<script setup lang="ts">
import { onMounted, onBeforeUnmount, watch, ref, computed } from 'vue'

const props = defineProps<{
  modelValue: boolean
  hintClosed?: string
  height?: string // ex.: '70vh' (default)
  peek?: number // px visível quando fechado (default 16)
  overlay?: boolean // mostra overlay (default true)
  closeOnOverlay?: boolean // fecha ao clicar overlay (default true)
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', v: boolean): void
  (e: 'open'): void
  (e: 'close'): void
}>()

// estado
const open = ref<boolean>(props.modelValue ?? false)
const isDragging = ref(false)
const startY = ref(0)
const dragOffset = ref<number | null>(null)

const panelRef = ref<HTMLDivElement | null>(null)
const panelHeight = ref(0)

// dimensões
const maxOffset = computed(() => {
  const peek = props.peek ?? 16
  return Math.max(0, panelHeight.value - peek)
})
function measure() {
  if (panelRef.value) {
    panelHeight.value = panelRef.value.getBoundingClientRect().height
  }
}

// v-model <-> estado
function toggle(v: boolean) {
  open.value = v
  emit('update:modelValue', v)
  if (v) {
    emit('open')
  } else {
    emit('close')
  }
}
watch(
  () => props.modelValue,
  (v) => (open.value = v),
  { immediate: true },
)

// scroll-lock centralizado
let prevBodyOverflow = ''
function lockScroll() {
  prevBodyOverflow = document.body.style.overflow
  document.body.style.overflow = 'hidden'
}
function unlockScroll() {
  document.body.style.overflow = prevBodyOverflow
}
watch(open, (v) => (v ? lockScroll() : unlockScroll()), { immediate: true })

// gestos
function startDrag(e: TouchEvent | MouseEvent) {
  isDragging.value = true
  startY.value = 'touches' in e ? e.touches[0].clientY : e.clientY
  dragOffset.value = open.value ? 0 : maxOffset.value
  window.addEventListener('touchmove', moveDrag, { passive: false })
  window.addEventListener('mousemove', moveDrag)
  window.addEventListener('touchend', endDrag)
  window.addEventListener('mouseup', endDrag)
}

function moveDrag(e: TouchEvent | MouseEvent) {
  if (dragOffset.value === null) return
  const clientY = 'touches' in e ? e.touches[0].clientY : e.clientY
  const dy = clientY - startY.value
  const next = (open.value ? 0 : maxOffset.value) + dy
  dragOffset.value = Math.min(Math.max(next, 0), maxOffset.value)
  e.preventDefault()
}

function endDrag() {
  if (dragOffset.value === null) {
    cleanup()
    return
  }
  const shouldClose = dragOffset.value > maxOffset.value / 6
  toggle(!shouldClose)
  dragOffset.value = null
  isDragging.value = false
  cleanup()
}

function cleanup() {
  window.removeEventListener('touchmove', moveDrag)
  window.removeEventListener('mousemove', moveDrag)
  window.removeEventListener('touchend', endDrag)
  window.removeEventListener('mouseup', endDrag)
}

// acessibilidade
function onKey(e: KeyboardEvent) {
  if (e.key === 'Escape' && open.value) toggle(false)
}

// lifecycle
onMounted(() => {
  window.addEventListener('keydown', onKey)
  measure()
  window.addEventListener('resize', measure)
})
onBeforeUnmount(() => {
  window.removeEventListener('keydown', onKey)
  window.removeEventListener('resize', measure)
  cleanup()
  unlockScroll()
})

// texto de dica quando fechado
const hintText = computed(() => props.hintClosed ?? 'Arraste para agendar viagem')

// animação
const translateStyle = computed(() => {
  const offset = dragOffset.value ?? (open.value ? 0 : maxOffset.value)
  return { transform: `translateY(${offset}px)` }
})
</script>

<template>
  <!-- overlay -->
  <div
    v-if="overlay !== false"
    class="fixed inset-0 z-40 bg-black/40 transition-opacity lg:hidden"
    :class="open ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'"
    @click="(closeOnOverlay ?? true) ? toggle(false) : null"
  />

  <!-- sheet -->
  <div
    class="fixed z-50 left-0 right-0 bottom-0 lg:hidden"
    :class="open ? 'pointer-events-auto' : 'pointer-events-none'"
    :style="{ height: height || '70vh' }"
  >
    <div
      ref="panelRef"
      class="absolute left-0 right-0 bottom-0 bg-white rounded-t-2xl shadow-2xl shadow-black/100 pointer-events-auto will-change-transform overscroll-contain"
      :class="isDragging ? 'transition-none' : 'transition-transform duration-300'"
      :style="{
        height: height || '70vh',
        paddingBottom: 'env(safe-area-inset-bottom)',
        touchAction: 'none',
        ...translateStyle,
      }"
      role="dialog"
      aria-modal="true"
    >
      <!-- handle -->
      <div
        class="w-full flex justify-center pt-2 pb-3 cursor-pointer select-none"
        @click="toggle(!open)"
        @mousedown.stop.prevent="startDrag"
        @touchstart.stop.prevent="startDrag"
      >
        <div class="flex items-center gap-2 text-gray-700 text-xl">
          <i
            class="text-xl"
            :class="[
              open
                ? 'fas fa-hand-point-down hand-nudge-down'
                : 'fas fa-hand-point-up hand-nudge-up',
            ]"
          ></i>
          <span>{{ open ? 'Arraste para ver o mapa' : hintText }}</span>
        </div>
      </div>

      <!-- conteúdo -->
      <div class="overflow-y-auto h-[calc(100%-20px)] p-4 overscroll-contain">
        <slot />
      </div>
    </div>
  </div>
</template>

<style scoped>
/* animação do incone */
@keyframes nudge-up {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-6px);
  }
}

@keyframes nudge-down {
  0%,
  100% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(6px);
  }
}

.hand-nudge-up {
  animation: nudge-up 1.2s ease-in-out infinite;
}
.hand-nudge-down {
  animation: nudge-down 1.2s ease-in-out infinite;
}
</style>
