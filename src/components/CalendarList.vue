<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { supabase, type Calendar } from '../lib/supabase'

const emit = defineEmits<{
  (e: 'selectCalendar', calendar: Calendar): void
}>()

const calendars = ref<Calendar[]>([])
const sharedCalendars = ref<Calendar[]>([])
const loading = ref(true)
const showForm = ref(false)
const newCalendar = ref({
  name: '',
  description: '',
  color: 'var(--primary)'
})
const editingCalendarId = ref<string | null>(null)
const showEditModal = ref(false)
const editCalendar = ref({
  name: '',
  description: '',
  color: 'var(--primary)',
  is_public: false
})

const loadCalendars = async () => {
  loading.value = true
  try {
    const { data: { user: currentUser } } = await supabase.auth.getUser()
    if (!currentUser) {
      calendars.value = []
      loading.value = false
      return
    }

    const { data: userCalendars, error: calError } = await supabase
      .from('calendars')
      .select('*')
      .eq('user_id', currentUser.id)
      .order('created_at', { ascending: false })

    if (calError) {
      console.error('Error fetching calendars:', calError)
      throw calError
    }

    console.log('User ID:', currentUser.id)
    console.log('Calendars loaded:', userCalendars)
    calendars.value = userCalendars || []

    const { data: shares } = await supabase
      .from('calendar_shares')
      .select('calendar_id')
      .eq('shared_with_email', currentUser.email)

    if (shares && shares.length > 0) {
      const calendarIds = shares.map((s: any) => s.calendar_id)
      const { data: shared } = await supabase
        .from('calendars')
        .select('*')
        .in('id', calendarIds)

      sharedCalendars.value = shared || []
    }
  } catch (error) {
    console.error('Error loading calendars:', error)
  } finally {
    loading.value = false
  }
}

const createCalendar = async () => {
  try {
    const user = await supabase.auth.getUser()
    if (!user.data.user) return

    const { error } = await supabase.from('calendars').insert({
      user_id: user.data.user.id,
      name: newCalendar.value.name,
      description: newCalendar.value.description,
      color: newCalendar.value.color
    })

    if (error) throw error

    newCalendar.value = { name: '', description: '', color: 'var(--primary)' }
    showForm.value = false
    await loadCalendars()
  } catch (error) {
    console.error('Error creating calendar:', error)
  }
}

const deleteCalendar = async (id: string) => {
  if (!confirm('¿Estás seguro de eliminar este calendario?')) return

  try {
    const { error } = await supabase
      .from('calendars')
      .delete()
      .eq('id', id)

    if (error) throw error
    await loadCalendars()
  } catch (error) {
    console.error('Error deleting calendar:', error)
  }
}

const startEditCalendar = (calendar: Calendar) => {
  editingCalendarId.value = calendar.id
  editCalendar.value = {
    name: calendar.name,
    description: calendar.description || '',
    color: calendar.color || 'var(--primary)',
    is_public: !!calendar.is_public
  }
  showEditModal.value = true
}

const cancelEditCalendar = () => {
  editingCalendarId.value = null
  showEditModal.value = false
}

const updateCalendar = async (id: string) => {
  try {
    const { error } = await supabase
      .from('calendars')
      .update({
        name: editCalendar.value.name,
        description: editCalendar.value.description,
        color: editCalendar.value.color,
        is_public: editCalendar.value.is_public
      })
      .eq('id', id)

    if (error) throw error
    editingCalendarId.value = null
    showEditModal.value = false
    await loadCalendars()
  } catch (error) {
    console.error('Error updating calendar:', error)
  }
}

let unsubscribe: (() => void) | null = null

onMounted(() => {
  loadCalendars()

  const { data: { subscription } } = supabase.auth.onAuthStateChange(() => {
    loadCalendars()
  })

  unsubscribe = subscription?.unsubscribe || null
})

onUnmounted(() => {
  if (unsubscribe) {
    unsubscribe()
  }
})
</script>

<template>
  <div class="calendar-list">
    <div class="header">
      <h2>Mis Calendarios</h2>
      <button @click="showForm = !showForm" class="btn-primary">
        {{ showForm ? 'Cancelar' : '+ Nuevo Calendario' }}
      </button>
    </div>

    <div v-if="showForm" class="calendar-form">
      <form @submit.prevent="createCalendar">
        <div class="form-group">
          <label>Nombre</label>
          <input v-model="newCalendar.name" type="text" placeholder="Mi calendario" required />
        </div>
        <div class="form-group">
          <label>Descripción</label>
          <input v-model="newCalendar.description" type="text" placeholder="Descripción opcional" />
        </div>
        <div class="form-group">
          <label>Color</label>
          <input v-model="newCalendar.color" type="color" />
        </div>
        <button type="submit" class="btn-primary">Crear</button>
      </form>
    </div>

    <div v-if="loading" class="loading">Cargando calendarios...</div>

    <div v-else>
      <div v-if="calendars.length === 0 && sharedCalendars.length === 0" class="empty">
        No tienes calendarios aún. Crea uno para empezar.
      </div>

      <div v-if="calendars.length > 0" class="calendar-section">
        <div
          v-for="calendar in calendars"
          :key="calendar.id"
          class="calendar-item"
          @click="emit('selectCalendar', calendar)"
        >
          <div
            class="calendar-color"
            :style="{ backgroundColor: calendar.color }"
          ></div>
          <div class="calendar-info">
            <div class="calendar-title-row">
              <h3>{{ calendar.name }}</h3>
              <span v-if="calendar.is_public" class="badge-public">Público</span>
            </div>
            <p v-if="calendar.description">{{ calendar.description }}</p>
          </div>
          <div class="calendar-actions">
            <button
              class="btn-secondary btn-small"
              @click.stop="startEditCalendar(calendar)"
            >
              Editar
            </button>
            <button
              @click.stop="deleteCalendar(calendar.id)"
              class="btn-delete"
              title="Eliminar"
            >
              ✖
            </button>
          </div>
        </div>
      </div>

      <div v-if="sharedCalendars.length > 0" class="calendar-section">
        <h3 class="section-title">Calendarios Compartidos Conmigo</h3>
        <div
          v-for="calendar in sharedCalendars"
          :key="calendar.id"
          class="calendar-item shared"
          @click="emit('selectCalendar', calendar)"
        >
          <div class="calendar-color" :style="{ backgroundColor: calendar.color }"></div>
          <div class="calendar-info">
            <div class="calendar-title-row">
              <h3>{{ calendar.name }}</h3>
              <span v-if="calendar.is_public" class="badge-public badge-public-shared">Público</span>
            </div>
            <p v-if="calendar.description">{{ calendar.description }}</p>
          </div>
          <span class="shared-badge">Compartido</span>
        </div>
      </div>
    </div>

    <div v-if="showEditModal && editingCalendarId" class="edit-modal">
      <div class="edit-modal-backdrop" @click="cancelEditCalendar"></div>
      <div class="edit-modal-content">
        <div class="edit-modal-header">
          <h3>Editar calendario</h3>
          <button class="btn-close" @click="cancelEditCalendar">✖</button>
        </div>
        <div class="form-group">
          <label>Nombre</label>
          <input v-model="editCalendar.name" type="text" />
        </div>
        <div class="form-group">
          <label>Descripción</label>
          <input v-model="editCalendar.description" type="text" />
        </div>
        <div class="form-group">
          <label>Color</label>
          <input v-model="editCalendar.color" type="color" />
        </div>
        <div class="form-group toggle-group">
          <label>
            <input v-model="editCalendar.is_public" type="checkbox" />
            <span>Calendario público</span>
          </label>
        </div>
        <div class="modal-actions">
          <button class="btn-primary" @click="updateCalendar(editingCalendarId)">
            Guardar
          </button>
          <button class="btn-secondary" @click="cancelEditCalendar">
            Cancelar
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.calendar-list {
  padding: 1rem;
  max-width: 800px;
  margin: 0 auto;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
}

h2 {
  font-size: 1.8rem;
  margin: 0;
}

.btn-primary {
  padding: 0.75rem 1.5rem;
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

.calendar-form {
  background: var(--surface-2);
  border-radius: 12px;
  padding: 1.5rem;
  margin-bottom: 1.5rem;
  border: 1px solid var(--border);
}

.form-group {
  margin-bottom: 1rem;
}

label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
}

input {
  width: 100%;
  padding: 0.75rem;
  border-radius: 8px;
  border: 1px solid var(--border-strong);
  background: var(--surface-2);
  color: inherit;
  font-size: 1rem;
  box-sizing: border-box;
}

input[type="color"] {
  height: 50px;
  cursor: pointer;
}

.loading,
.empty {
  text-align: center;
  padding: 2rem;
  color: var(--text-muted);
}

.calendar-section {
  margin-bottom: 2rem;
}

.section-title {
  font-size: 1.2rem;
  margin-bottom: 1rem;
  color: var(--text-muted-strong);
}

.calendar-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  background: var(--surface-2);
  border-radius: 12px;
  margin-bottom: 0.75rem;
  cursor: pointer;
  transition: all 0.2s;
  border: 1px solid var(--border);
}

.calendar-item:hover {
  background: var(--surface-3);
  transform: translateY(-2px);
}

.calendar-color {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  flex-shrink: 0;
}

.calendar-info {
  flex: 1;
}

.calendar-actions {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

.btn-small {
  padding: 0.5rem 0.9rem;
  font-size: 0.9rem;
}

.btn-secondary {
  padding: 0.5rem 0.9rem;
  border-radius: 8px;
  border: none;
  background: var(--primary);
  color: white;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-secondary:hover {
  background: var(--primary-hover);
}

.edit-modal {
  position: fixed;
  inset: 0;
  z-index: 1200;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
}

.edit-modal-backdrop {
  position: absolute;
  inset: 0;
  background: var(--bg-gradient);
}

.edit-modal-content {
  position: relative;
  width: 100%;
  max-width: 520px;
  background: var(--surface-solid);
  border: 1px solid var(--border);
  border-radius: 14px;
  padding: 1.25rem;
  z-index: 1;
}

.edit-modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  margin-bottom: 1rem;
}

.edit-modal-header h3 {
  margin: 0;
  font-size: 1.2rem;
}

.btn-close {
  border: none;
  background: transparent;
  color: var(--text);
  cursor: pointer;
  font-size: 1.1rem;
}

.toggle-group label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
}

.toggle-group input[type="checkbox"] {
  width: 18px;
  height: 18px;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  margin-top: 1rem;
}
.calendar-info h3 {
  margin: 0 0 0.25rem 0;
  font-size: 1.1rem;
}

.calendar-title-row {
  display: flex;
  align-items: center;
  gap: 0.6rem;
}

.badge-public {
  display: inline-flex;
  align-items: center;
  padding: 0.15rem 0.5rem;
  border-radius: 999px;
  background: var(--accent-bg-strong);
  color: var(--primary);
  font-size: 0.7rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.badge-public-shared {
  background: var(--surface-2);
  color: var(--text-muted-strong);
}

.calendar-info p {
  margin: 0;
  color: var(--text-muted);
  font-size: 0.9rem;
}

.btn-delete {
  padding: 0.5rem 0.75rem;
  border: none;
  background: var(--danger-bg);
  color: var(--danger);
  border-radius: 6px;
  cursor: pointer;
  transition: background 0.2s;
  font-size: 1rem;
}

.btn-delete:hover {
  background: var(--danger-bg-hover);
}

.shared-badge {
  padding: 0.25rem 0.75rem;
  background: var(--accent-bg-strong);
  color: var(--primary);
  border-radius: 12px;
  font-size: 0.85rem;
  font-weight: 500;
}
</style>



