<script setup lang="ts">
import { onMounted } from 'vue'
import { RouterView } from 'vue-router'
import { useAuth } from '@/composables/auth/useAuth'

const { loadUserFromToken } = useAuth()

onMounted(() => {
  loadUserFromToken()
})
</script>

<template>
  <RouterView />
</template>
