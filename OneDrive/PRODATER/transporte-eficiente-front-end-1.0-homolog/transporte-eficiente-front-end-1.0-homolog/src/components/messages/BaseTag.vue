<script setup lang="ts">

const props = defineProps({
  icon: { type: String, default: '' },
  avatar: { type: String, default: '' },
  closable: { type: Boolean, default: false },
  tagId: { type: String, default: 'tag-default' },
  isDisabled: { type: Boolean, default: false },
})

const emit = defineEmits(['close', 'click'])

const textId = `text-${props.tagId}`

function handleClose() {
  emit('close')
}

function handleClick() {
  if (!props.isDisabled) {
    emit('click')
  }
}
</script>


<template>
  <span
    class="br-tag interaction"
    :class="{ disabled: isDisabled }"
    :id="tagId"
    @click="handleClick"
  >
    <template v-if="avatar">
      <img :src="avatar" alt="avatar" class="rounded-full w-6 h-6 object-cover me-2" />
    </template>

    <template v-if="icon && !avatar">
      <i :class="['mr-1', icon]" aria-hidden="true" />
    </template>

    <span :id="textId">
      <slot />
    </span>

    <button
      v-if="closable"
      class="br-button inverted circle"
      type="button"
      aria-label="Fechar"
      :aria-describedby="textId"
      :data-dismiss="tagId"
      :disabled="isDisabled"
      @click.stop="handleClose"
    >
      <i class="fas fa-times" aria-hidden="true" />
    </button>
  </span>
</template>



<!--
//Modelo de uso

// Eventos para as tags
function handleTagClick() {
  console.log('Tag clicada')
}

function handleTagClose() {
  console.log('Fechou a tag')
}

const nomeTexto = 'Texto dinamico'
    <BaseTag tagId="tag1" avatar="/imgs/LOGO_PMT_25.jpg" @click="handleTagClick"
      >Texto aqui</BaseTag
    >
    <BaseTag
      tagId="tag2"
      avatar="/imgs/LOGO_PMT_25.jpg"
      closable
      @click="handleTagClick"
      @close="handleTagClose"
      >Texto aqui</BaseTag
    >
    <BaseTag tagId="tag3" closable @close="handleTagClose">Texto aqui</BaseTag>
    <BaseTag tagId="tag4" icon="fas fa-car" closable @close="handleTagClose">Texto aqui</BaseTag>
    <BaseTag tagId="tag5" icon="fas fa-bus">Texto aqui</BaseTag>
    <BaseTag tagId="tag6">Texto aqui</BaseTag>
    <BaseTag tagId="tag-dinamica">{{ nomeTexto }}</BaseTag>
    <BaseTag icon="fas fa-car" tag-id="exemplo-tag" :is-disabled="true">Texto aqui</BaseTag>

-->
