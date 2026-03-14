<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps({
  title: String,
  subtitle: String,
  avatar: String,
  showMenuButton: Boolean,
  primaryButtonText: String,
  secondaryIcon: String,
  secondaryIconLabel: String,
  tertiaryIcon: String,
  tertiaryIconLabel: String,
  disabled: Boolean,
})

const hasHeader = computed(() => {
  return !!(props.title || props.subtitle || props.avatar || props.showMenuButton)
})

const showFooter = computed(() => {
  return !!(props.primaryButtonText || props.secondaryIcon || props.tertiaryIcon)
})
</script>

<template>
  <div class="col-sm-6 col-md-4 col-lg-3">
    <div class="br-card" >
      <div class="card-header" v-if="hasHeader">
        <div class="d-flex">
          <span class="br-avatar mt-1" v-if="avatar" :title="title">
            <span class="content">
              <img :src="avatar" alt="Avatar" style="object-fit: cover" />
            </span>
          </span>
          <div class="ml-3" v-if="title || subtitle">
            <div v-if="title" class="text-weight-semi-bold text-up-02">{{ title }}</div>
            <div v-if="subtitle">{{ subtitle }}</div>
          </div>
          <div class="ml-auto" v-if="showMenuButton">
            <button
              class="br-button circle"
              type="button"
              aria-label="Menu"
              @click="$emit('clickMenu')"
            >
              <i class="fas fa-ellipsis-v" aria-hidden="true"></i>
            </button>
          </div>
        </div>
      </div>

      <div class="card-content">
        <slot></slot>
      </div>

      <div class="card-footer" v-if="showFooter">
        <div class="d-flex">
          <div v-if="primaryButtonText">
            <button
              class="br-button"
              type="button"
              @click="$emit('clickPrimary')"
              :disabled="disabled"
            >
              {{ primaryButtonText }}
            </button>
          </div>
          <div class="ml-auto">
            <button
              v-if="secondaryIcon"
              class="br-button circle"
              type="button"
              :aria-label="secondaryIconLabel"
              @click="$emit('clickIcon1')"
              :disabled="disabled"
            >
              <i :class="secondaryIcon" aria-hidden="true"></i>
            </button>
            <button
              v-if="tertiaryIcon"
              class="br-button circle"
              type="button"
              :aria-label="tertiaryIconLabel"
              @click="$emit('clickIcon2')"
              :disabled="disabled"
            >
              <i :class="tertiaryIcon" aria-hidden="true"></i>
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>


<!--
Modelo de uso

// Eventos para card
const abrirMenu = () => {
  console.log('Menu clicado')
}
const acaoPrincipal = () => {
  console.log('Botão principal clicado')
}
const acaoIcone1 = () => {
  console.log('Ícone 1 clicado')
}
const acaoIcone2 = () => {
  console.log('Ícone 2 clicado')
}

// podem ser usado de forma dinamica
// const titulo = ref('Maria Amorim')
// const subtitulo = ref('UX Designer')
const imagemAvatar = ref('/imgs/LOGO_PMT_25.jpg')

   <BaseCard
      :avatar="imagemAvatar"   //pode ser dinamico ou texto estatico
      title="Maria Amorim"     //pode ser dinamico ou texto estatico
      subtitle="UX Designer"   //pode ser dinamico ou texto estatico
      showMenuButton
      :showPrimaryButton="true"
      :showIconButtons="true"
      primaryButtonText="Ação principal"
      secondaryIcon="fas fa-heart"
      tertiaryIcon="fas fa-share-alt"
      @clickMenu="abrirMenu"
      @clickPrimary="acaoPrincipal"
      @clickIcon1="acaoIcone1"
      @clickIcon2="acaoIcone2"
    >
      <template #default>
        <p>
          Lorem ipsum dolor sit, amet consectetur adipisicing elit. Tempore perferendis nam porro
          atque ex at, numquam non optio ab eveniet error vel ad exercitationem, earum et fugiat
          recusandae harum? Assumenda.
        </p>
      </template>
    </BaseCard>

-->
