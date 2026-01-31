<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { supabase, type Calendar } from '../lib/supabase'

const props = defineProps<{
  calendar: Calendar
}>()

const emit = defineEmits<{
  (e: 'close'): void
  (e: 'updated', value: boolean): void
}>()

const copied = ref(false)
const isPublic = ref(!!props.calendar.is_public)
const saving = ref(false)
const saveError = ref('')

const publicUrl = computed(() => {
  return `${window.location.origin}/?public=${props.calendar.id}`
})

const copyUrl = async () => {
  try {
    await navigator.clipboard.writeText(publicUrl.value)
    copied.value = true
    setTimeout(() => {
      copied.value = false
    }, 1500)
  } catch (error) {
    console.error('Error copying url:', error)
  }
}

const updatePublicStatus = async (value: boolean) => {
  saving.value = true
  saveError.value = ''
  try {
    const { error } = await supabase
      .from('calendars')
      .update({ is_public: value })
      .eq('id', props.calendar.id)

    if (error) throw error
    isPublic.value = value
    emit('updated', value)
  } catch (error: any) {
    saveError.value = 'No se pudo actualizar la visibilidad'
    isPublic.value = !value
  } finally {
    saving.value = false
  }
}

watch(
  () => props.calendar.is_public,
  value => {
    isPublic.value = !!value
  }
)
</script>

<template>
  <div class="modal-overlay" @click.self="emit('close')">
    <div class="modal-content">
      <div class="modal-header">
        <h2>Compartir Calendario</h2>
        <button @click="emit('close')" class="btn-close">✖</button>
      </div>

      <div class="calendar-info">
        <div class="calendar-color" :style="{ backgroundColor: calendar.color }"></div>
        <div>
          <h3>{{ calendar.name }}</h3>
          <p v-if="calendar.description">{{ calendar.description }}</p>
        </div>
      </div>

      <div class="share-form">
        <h3>Enlace público</h3>
        <div class="public-toggle">
          <label>
            <input
              type="checkbox"
              :checked="isPublic"
              :disabled="saving"
              @change="updatePublicStatus(($event.target as HTMLInputElement).checked)"
            />
            <span>Calendario público</span>
          </label>
          <span v-if="saving" class="public-status">Guardando...</span>
          <span v-else-if="saveError" class="public-status error">{{ saveError }}</span>
        </div>
        <div class="public-link">
          <input type="text" :value="publicUrl" readonly />
          <button class="btn-primary btn-copy" @click="copyUrl">
            {{ copied ? 'Copiado' : 'Copiar' }}
          </button>
        </div>
        <p class="public-note">
          {{ isPublic ? 'Este enlace permite solo lectura del calendario.' : 'Activa el calendario público para que el enlace funcione.' }}
        </p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 1rem;
}

.modal-content {
  background: var(--surface-solid);
  border-radius: 16px;
  width: 100%;
  max-width: 600px;
  max-height: 90vh;
  overflow-y: auto;
  border: 1px solid var(--border);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid var(--border);
}

.modal-header h2 {
  margin: 0;
  font-size: 1.5rem;
}

.btn-close {
  padding: 0.5rem;
  border: none;
  background: transparent;
  color: var(--text-muted);
  cursor: pointer;
  font-size: 1.5rem;
  line-height: 1;
  transition: color 0.2s;
}

.btn-close:hover {
  color: var(--text);
}

.calendar-info {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.5rem;
  background: var(--surface-1);
}

.calendar-color {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  flex-shrink: 0;
}

.calendar-info h3 {
  margin: 0;
  font-size: 1.2rem;
}

.calendar-info p {
  margin: 0.25rem 0 0 0;
  color: var(--text-muted);
  font-size: 0.9rem;
}

.share-form {
  padding: 1.5rem;
}

.share-form h3 {
  margin: 0 0 1rem 0;
  font-size: 1.1rem;
}

.public-link {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 0.75rem;
  align-items: center;
}

.public-toggle {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  margin-bottom: 0.75rem;
}

.public-toggle label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
  font-weight: 500;
}

.public-toggle input[type="checkbox"] {
  width: 18px;
  height: 18px;
  cursor: pointer;
}

.public-status {
  font-size: 0.85rem;
  color: var(--text-muted);
}

.public-status.error {
  color: var(--danger);
}

input[type="text"] {
  width: 100%;
  padding: 0.75rem;
  border-radius: 8px;
  border: 1px solid var(--border-strong);
  background: var(--surface-2);
  color: inherit;
  font-size: 1rem;
  box-sizing: border-box;
}

.btn-primary {
  padding: 0.75rem 1rem;
  border-radius: 8px;
  border: none;
  background: var(--primary);
  color: white;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-primary:hover {
  background: var(--primary-hover);
}

.btn-copy {
  white-space: nowrap;
}

.public-note {
  margin: 0.75rem 0 0 0;
  color: var(--text-muted);
  font-size: 0.9rem;
}
</style>
