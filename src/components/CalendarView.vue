<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase, type Calendar, type Booking } from '../lib/supabase'

const props = defineProps<{
  calendar: Calendar
}>()

const emit = defineEmits<{
  (e: 'back'): void
  (e: 'share'): void
}>()

const bookings = ref<Booking[]>([])
const loading = ref(true)
const showForm = ref(false)
const newBooking = ref({
  title: '',
  description: '',
  startDate: new Date().toISOString().split('T')[0],
  startTime: '09:00',
  endDate: new Date().toISOString().split('T')[0],
  endTime: '10:00'
})

const currentWeek = ref<Date[]>([])
const weekStart = ref(new Date())
const viewMode = ref<'month' | 'week' | 'list'>('month')
const currentMonth = ref(new Date())
const currentMonthDates = ref<Date[]>([])
const listMonth = ref(new Date())
const selectedDate = ref(new Date())
const showDayModal = ref(false)
const editingBookingId = ref<string | null>(null)
const editBooking = ref({
  title: '',
  description: '',
  startDate: '',
  startTime: '',
  endDate: '',
  endTime: ''
})

const formatTime = (date: string) => {
  return new Date(date).toLocaleTimeString('es-ES', {
    hour: '2-digit',
    minute: '2-digit'
  })
}

const formatDate = (date: string) => {
  return new Date(date).toLocaleDateString('es-ES', {
    day: 'numeric',
    month: 'short'
  })
}

const formatDateFromDate = (date: Date) => {
  return date.toLocaleDateString('es-ES', {
    day: 'numeric',
    month: 'short'
  })
}

const getWeekDates = (startDate: Date) => {
  const dates = []
  const start = new Date(startDate)
  const day = start.getDay()
  const diff = (day + 6) % 7
  start.setDate(start.getDate() - diff)

  for (let i = 0; i < 7; i++) {
    const date = new Date(start)
    date.setDate(start.getDate() + i)
    dates.push(date)
  }

  return dates
}

const getMonthDates = (dateInMonth: Date) => {
  const dates = []
  const start = new Date(dateInMonth.getFullYear(), dateInMonth.getMonth(), 1)
  const day = start.getDay()
  const diff = (day + 6) % 7
  start.setDate(start.getDate() - diff)

  for (let i = 0; i < 42; i++) {
    const date = new Date(start)
    date.setDate(start.getDate() + i)
    dates.push(date)
  }

  return dates
}

const previousWeek = () => {
  weekStart.value = new Date(weekStart.value.setDate(weekStart.value.getDate() - 7))
  currentWeek.value = getWeekDates(weekStart.value)
}

const nextWeek = () => {
  weekStart.value = new Date(weekStart.value.setDate(weekStart.value.getDate() + 7))
  currentWeek.value = getWeekDates(weekStart.value)
}

const previousMonth = () => {
  currentMonth.value = new Date(currentMonth.value.getFullYear(), currentMonth.value.getMonth() - 1, 1)
  currentMonthDates.value = getMonthDates(currentMonth.value)
  selectedDate.value = new Date(currentMonth.value)
}

const nextMonth = () => {
  currentMonth.value = new Date(currentMonth.value.getFullYear(), currentMonth.value.getMonth() + 1, 1)
  currentMonthDates.value = getMonthDates(currentMonth.value)
  selectedDate.value = new Date(currentMonth.value)
}

const previousListMonth = () => {
  listMonth.value = new Date(listMonth.value.getFullYear(), listMonth.value.getMonth() - 1, 1)
}

const nextListMonth = () => {
  listMonth.value = new Date(listMonth.value.getFullYear(), listMonth.value.getMonth() + 1, 1)
}

const formatMonthTitle = (date: Date) => {
  return date.toLocaleDateString('es-ES', { month: 'long', year: 'numeric' })
}

const isSameMonth = (date: Date) => {
  return date.getMonth() === currentMonth.value.getMonth() &&
    date.getFullYear() === currentMonth.value.getFullYear()
}

const isSameDay = (a: Date, b: Date) => {
  return a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
}

const bookingsForDate = (date: Date) => {
  const dayDate = new Date(date.getFullYear(), date.getMonth(), date.getDate())

  return bookings.value.filter(b => {
    const startDate = new Date(b.start_time)
    const endDate = new Date(b.end_time)
    const startDateOnly = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate())
    const endDateOnly = new Date(endDate.getFullYear(), endDate.getMonth(), endDate.getDate())

    return dayDate >= startDateOnly && dayDate <= endDateOnly
  }).sort((a, b) => new Date(a.start_time).getTime() - new Date(b.start_time).getTime())
}

const bookingsForMonth = (month: Date) => {
  return bookings.value.filter(b => {
    const startDate = new Date(b.start_time)
    return startDate.getMonth() === month.getMonth() && startDate.getFullYear() === month.getFullYear()
  })
}

const handleDayClick = (day: Date) => {
  selectedDate.value = new Date(day)
  if (bookingsForDate(day).length > 0) {
    showDayModal.value = true
  }
}

const closeDayModal = () => {
  showDayModal.value = false
  editingBookingId.value = null
}

const loadBookings = async () => {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('bookings')
      .select('*')
      .eq('calendar_id', props.calendar.id)
      .order('start_time', { ascending: true })

    if (error) throw error
    bookings.value = data || []
  } catch (error) {
    console.error('Error loading bookings:', error)
  } finally {
    loading.value = false
  }
}

const createBooking = async () => {
  try {
    const user = await supabase.auth.getUser()
    if (!user.data.user) return

    const startDateTime = new Date(`${newBooking.value.startDate}T${newBooking.value.startTime}`)
    const endDateTime = new Date(`${newBooking.value.endDate}T${newBooking.value.endTime}`)

    const { error } = await supabase.from('bookings').insert({
      calendar_id: props.calendar.id,
      user_id: user.data.user.id,
      title: newBooking.value.title,
      description: newBooking.value.description,
      start_time: startDateTime.toISOString(),
      end_time: endDateTime.toISOString()
    })

    if (error) throw error

    newBooking.value = {
      title: '',
      description: '',
      startDate: new Date().toISOString().split('T')[0],
      startTime: '09:00',
      endDate: new Date().toISOString().split('T')[0],
      endTime: '10:00'
    }
    showForm.value = false
    await loadBookings()
  } catch (error: any) {
    alert('Error al crear evento: ' + error.message)
  }
}

const startEditBooking = (booking: Booking) => {
  const start = new Date(booking.start_time)
  const end = new Date(booking.end_time)
  editBooking.value = {
    title: booking.title,
    description: booking.description || '',
    startDate: start.toISOString().split('T')[0],
    startTime: start.toTimeString().slice(0, 5),
    endDate: end.toISOString().split('T')[0],
    endTime: end.toTimeString().slice(0, 5)
  }
  editingBookingId.value = booking.id
}

const cancelEditBooking = () => {
  editingBookingId.value = null
}

const updateBooking = async (id: string) => {
  try {
    const startDateTime = new Date(`${editBooking.value.startDate}T${editBooking.value.startTime}`)
    const endDateTime = new Date(`${editBooking.value.endDate}T${editBooking.value.endTime}`)

    const { error } = await supabase
      .from('bookings')
      .update({
        title: editBooking.value.title,
        description: editBooking.value.description,
        start_time: startDateTime.toISOString(),
        end_time: endDateTime.toISOString()
      })
      .eq('id', id)

    if (error) throw error

    editingBookingId.value = null
    await loadBookings()
  } catch (error: any) {
    alert('Error al actualizar evento: ' + error.message)
  }
}

const deleteBooking = async (id: string) => {
  if (!confirm('¿Eliminar este evento?')) return

  try {
    const { error } = await supabase
      .from('bookings')
      .delete()
      .eq('id', id)

    if (error) throw error
    await loadBookings()
  } catch (error) {
    console.error('Error deleting booking:', error)
  }
}

onMounted(() => {
  loadBookings()
  currentWeek.value = getWeekDates(weekStart.value)
  currentMonthDates.value = getMonthDates(currentMonth.value)
})
</script>

<template>
  <div class="calendar-view">
    <div class="header">
      <div class="calendar-header-info">
        <div class="calendar-color" :style="{ backgroundColor: calendar.color }"></div>
        <div>
          <div class="calendar-title-row">
            <h2>{{ calendar.name }}</h2>
            <span v-if="calendar.is_public" class="badge-public">Público</span>
          </div>
          <p v-if="calendar.description">{{ calendar.description }}</p>
        </div>
      </div>
      <div class="header-actions">
        <button @click="showForm = !showForm" class="btn-primary">
          {{ showForm ? 'Cancelar' : '+ Nuevo Evento' }}
        </button>
        <button @click="emit('share')" class="btn-secondary">Compartir</button>
        <button @click="emit('back')" class="btn-back">Mis calendarios</button>
      </div>
    </div>

    <div v-if="showForm" class="booking-form">
      <form @submit.prevent="createBooking">
        <div class="form-row">
          <div class="form-group">
            <label>Título</label>
            <input v-model="newBooking.title" type="text" placeholder="Reunión importante" required />
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label>Fecha desde</label>
            <input v-model="newBooking.startDate" type="date" required />
          </div>
          <div class="form-group">
            <label>Fecha hasta</label>
            <input v-model="newBooking.endDate" type="date" required />
          </div>
        </div>
        <div class="form-row">
          <div class="form-group">
            <label>Hora inicio</label>
            <input v-model="newBooking.startTime" type="time" required />
          </div>
          <div class="form-group">
            <label>Hora fin</label>
            <input v-model="newBooking.endTime" type="time" required />
          </div>
        </div>
        <div class="form-group">
          <label>Descripción</label>
          <textarea v-model="newBooking.description" placeholder="Detalles opcionales"></textarea>
        </div>
        <button type="submit" class="btn-primary">Crear Evento</button>
      </form>
    </div>

    <div v-if="viewMode === 'week'" class="week-navigation">
      <div class="nav-buttons">
        <button @click="previousWeek" class="btn-nav">←</button>
        <h3>Semana del {{ formatDate(currentWeek[0]?.toISOString()) }}</h3>
        <button @click="nextWeek" class="btn-nav">→</button>
      </div>
      <div class="view-toggle">
        <button
          class="btn-toggle"
          :class="{ active: String(viewMode) === 'month' }"
          @click="viewMode = 'month'"
        >
          Mes
        </button>
        <button
          class="btn-toggle"
          :class="{ active: String(viewMode) === 'week' }"
          @click="viewMode = 'week'"
        >
          Semana
        </button>
        <button
          class="btn-toggle"
          :class="{ active: String(viewMode) === 'list' }"
          @click="viewMode = 'list'"
        >
          Lista
        </button>
      </div>
    </div>

    <div v-else-if="viewMode === 'month'" class="month-navigation">
      <div class="nav-buttons">
        <button @click="previousMonth" class="btn-nav">←</button>
        <h3>{{ formatMonthTitle(currentMonth) }}</h3>
        <button @click="nextMonth" class="btn-nav">→</button>
      </div>
      <div class="view-toggle">
        <button
          class="btn-toggle"
          :class="{ active: String(viewMode) === 'month' }"
          @click="viewMode = 'month'"
        >
          Mes
        </button>
        <button
          class="btn-toggle"
          :class="{ active: String(viewMode) === 'week' }"
          @click="viewMode = 'week'"
        >
          Semana
        </button>
        <button
          class="btn-toggle"
          :class="{ active: String(viewMode) === 'list' }"
          @click="viewMode = 'list'"
        >
          Lista
        </button>
      </div>
    </div>

    <div v-else-if="viewMode === 'list'" class="list-navigation">
      <div class="nav-buttons">
        <button @click="previousListMonth" class="btn-nav">←</button>
        <h3>{{ formatMonthTitle(listMonth) }}</h3>
        <button @click="nextListMonth" class="btn-nav">→</button>
      </div>
      <div class="view-toggle">
        <button
          class="btn-toggle"
          :class="{ active: String(viewMode) === 'month' }"
          @click="viewMode = 'month'"
        >
          Mes
        </button>
        <button
          class="btn-toggle"
          :class="{ active: String(viewMode) === 'week' }"
          @click="viewMode = 'week'"
        >
          Semana
        </button>
        <button
          class="btn-toggle"
          :class="{ active: String(viewMode) === 'list' }"
          @click="viewMode = 'list'"
        >
          Lista
        </button>
      </div>
    </div>

    <div v-if="loading" class="loading">Cargando eventos...</div>

    <div v-else-if="viewMode === 'week'" class="week-view">
      <div
        v-for="(day, index) in currentWeek"
        :key="index"
        class="day-column"
      >
        <div class="day-header">
          <div class="day-name">{{ day.toLocaleDateString('es-ES', { weekday: 'short' }) }}</div>
          <div class="day-number">{{ day.getDate() }}</div>
        </div>
        <div class="day-bookings">
          <div
            v-for="booking in bookingsForDate(day)"
            :key="booking.id"
            class="booking-item"
            :style="{ borderLeftColor: calendar.color }"
          >
            <div class="booking-time">
              {{ formatTime(booking.start_time) }} - {{ formatTime(booking.end_time) }}
            </div>
            <div class="booking-title">{{ booking.title }}</div>
            <div v-if="booking.description" class="booking-description">
              {{ booking.description }}
            </div>
            <button
              @click="deleteBooking(booking.id)"
              class="btn-delete-small"
              title="Eliminar"
            >
              ✖
            </button>
          </div>
          <div v-if="bookingsForDate(day).length === 0" class="no-bookings">
            Sin eventos
          </div>
        </div>
      </div>
    </div>

    <div v-else-if="viewMode === 'month'" class="month-view">
      <div class="month-header">
        <div class="month-header-cell" v-for="day in ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom']" :key="day">
          {{ day }}
        </div>
      </div>
      <div class="month-grid">
        <div
          v-for="(day, index) in currentMonthDates"
          :key="index"
          class="month-day"
          :class="{
            'is-other-month': !isSameMonth(day),
            'is-selected': isSameDay(day, selectedDate),
            'has-bookings': bookingsForDate(day).length > 0
          }"
          @click="handleDayClick(day)"
        >
          <div class="month-day-number">{{ day.getDate() }}</div>
          <div class="month-day-events">
            <div
              v-for="booking in bookingsForDate(day).slice(0, 2)"
              :key="booking.id"
              class="month-event-item"
              :style="{ backgroundColor: calendar.color + '20', borderLeftColor: calendar.color }"
            >
              <span class="month-event-time">{{ formatTime(booking.start_time) }}</span>
              <span class="month-event-title">{{ booking.title }}</span>
            </div>
            <div v-if="bookingsForDate(day).length > 2" class="month-event-more">
              +{{ bookingsForDate(day).length - 2 }} más
            </div>
            <div v-if="bookingsForDate(day).length === 0" class="month-day-empty">
              Sin eventos
            </div>
          </div>
        </div>
      </div>

    </div>

    <div v-else-if="viewMode === 'list'" class="list-view">
      <div v-if="bookingsForMonth(listMonth).length === 0" class="no-bookings">
        No hay eventos en este mes
      </div>
      <div v-else class="list-container">
        <div
          v-for="booking in bookingsForMonth(listMonth)"
          :key="booking.id"
          class="list-item"
          :style="{ borderLeftColor: calendar.color }"
        >
          <div class="list-item-header">
            <div class="list-item-date">
              <div class="list-date-day">
                {{ formatDate(booking.start_time) }}
                <span v-if="formatDate(booking.start_time) !== formatDate(booking.end_time)">
                  - {{ formatDate(booking.end_time) }}
                </span>
              </div>
              <div class="list-date-time">
                {{ formatTime(booking.start_time) }} - {{ formatTime(booking.end_time) }}
              </div>
            </div>
            <div class="list-item-content">
              <div class="list-item-title">{{ booking.title }}</div>
              <div v-if="booking.description" class="list-item-description">
                {{ booking.description }}
              </div>
            </div>
          </div>
          <div class="list-item-actions">
            <button class="btn-secondary btn-small" @click="startEditBooking(booking); showDayModal = true; selectedDate = new Date(booking.start_time)">
              Editar
            </button>
            <button
              @click="deleteBooking(booking.id)"
              class="btn-delete-small btn-small"
              title="Eliminar"
            >
              ✖
            </button>
          </div>
        </div>
      </div>
    </div>

    <div v-if="showDayModal" class="day-modal">
      <div class="day-modal-backdrop" @click="closeDayModal"></div>
      <div class="day-modal-content">
        <div class="day-modal-header">
          <h4>Eventos del {{ formatDateFromDate(selectedDate) }}</h4>
          <button class="btn-close" @click="closeDayModal">✖</button>
        </div>
        <div v-if="bookingsForDate(selectedDate).length === 0" class="no-bookings">
          Sin eventos
        </div>
        <div
          v-for="booking in bookingsForDate(selectedDate)"
          :key="booking.id"
          class="booking-item"
          :style="{ borderLeftColor: calendar.color }"
        >
          <div v-if="editingBookingId === booking.id" class="booking-edit">
            <div class="form-row">
              <div class="form-group">
                <label>Título</label>
                <input v-model="editBooking.title" type="text" required />
              </div>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>Fecha desde</label>
                <input v-model="editBooking.startDate" type="date" required />
              </div>
              <div class="form-group">
                <label>Fecha hasta</label>
                <input v-model="editBooking.endDate" type="date" required />
              </div>
            </div>
            <div class="form-row">
              <div class="form-group">
                <label>Hora inicio</label>
                <input v-model="editBooking.startTime" type="time" required />
              </div>
              <div class="form-group">
                <label>Hora fin</label>
                <input v-model="editBooking.endTime" type="time" required />
              </div>
            </div>
            <div class="form-group">
              <label>Descripción</label>
              <textarea v-model="editBooking.description" placeholder="Detalles opcionales"></textarea>
            </div>
            <div class="booking-actions">
              <button class="btn-primary btn-small" @click="updateBooking(booking.id)">
                Guardar
              </button>
              <button class="btn-secondary btn-small" @click="cancelEditBooking">
                Cancelar
              </button>
            </div>
          </div>
          <div v-else>
            <div class="booking-time">
              {{ formatTime(booking.start_time) }} - {{ formatTime(booking.end_time) }}
            </div>
            <div class="booking-title">{{ booking.title }}</div>
            <div v-if="booking.description" class="booking-description">
              {{ booking.description }}
            </div>
            <div class="booking-actions">
              <button class="btn-secondary btn-small" @click="startEditBooking(booking)">
                Editar
              </button>
              <button
                @click="deleteBooking(booking.id)"
                class="btn-delete-small btn-small"
                title="Eliminar"
              >
                ✖
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.calendar-view {
  padding: 1rem;
  max-width: 1400px;
  margin: 0 auto;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
  gap: 1rem;
}

.calendar-header-info {
  display: flex;
  align-items: center;
  gap: 1rem;
  flex: 1;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex-wrap: wrap;
  justify-content: flex-end;
}

.calendar-color {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  flex-shrink: 0;
}

.calendar-header-info h2 {
  margin: 0;
  font-size: 1.8rem;
}

.calendar-title-row {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.badge-public {
  display: inline-flex;
  align-items: center;
  padding: 0.2rem 0.6rem;
  border-radius: 999px;
  background: var(--accent-bg-strong);
  color: var(--primary);
  font-size: 0.75rem;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.calendar-header-info p {
  margin: 0.25rem 0 0 0;
  color: var(--text-muted);
}

.btn-back {
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  border: 1px solid var(--border-strong);
  background: var(--surface-2);
  color: inherit;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-back:hover {
  background: var(--surface-3);
}

.btn-secondary {
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  border: 1px solid var(--primary);
  background: transparent;
  color: var(--primary);
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-secondary:hover {
  background: var(--accent-bg);
}

.actions {
  margin-bottom: 1.5rem;
}

.view-toggle {
  display: inline-flex;
  border: 1px solid var(--border-strong);
  border-radius: 8px;
  overflow: hidden;
}

.btn-toggle {
  padding: 0.6rem 1rem;
  border: none;
  background: transparent;
  color: inherit;
  cursor: pointer;
  font-weight: 600;
  transition: background 0.2s;
}

.btn-toggle.active {
  background: var(--accent-bg-strong);
  color: var(--primary);
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

.booking-form {
  background: var(--surface-2);
  border-radius: 12px;
  padding: 1.5rem;
  margin-bottom: 1.5rem;
  border: 1px solid var(--border);
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
  margin-bottom: 1rem;
}

.form-group {
  margin-bottom: 1rem;
}

label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  font-size: 0.9rem;
}

input,
textarea {
  width: 100%;
  padding: 0.75rem;
  border-radius: 8px;
  border: 1px solid var(--border-strong);
  background: var(--surface-2);
  color: inherit;
  font-size: 1rem;
  box-sizing: border-box;
  font-family: inherit;
}

textarea {
  resize: vertical;
  min-height: 80px;
}

.week-navigation {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 2rem;
  margin-bottom: 1.5rem;
  position: relative;
}

.month-navigation {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 2rem;
  margin-bottom: 1.5rem;
  position: relative;
}

.week-navigation h3 {
  margin: 0;
  font-size: 1.2rem;
}

.month-navigation h3 {
  margin: 0;
  font-size: 1.2rem;
  text-transform: capitalize;
}

.list-navigation {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 2rem;
  margin-bottom: 1.5rem;
  position: relative;
}

.list-navigation .view-toggle,
.month-navigation .view-toggle,
.week-navigation .view-toggle {
  margin-left: auto;
}

.list-navigation h3 {
  margin: 0;
  font-size: 1.2rem;
}

.nav-buttons {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.nav-buttons h3 {
  margin: 0 0.5rem;
}

.btn-nav {
  padding: 0.5rem 1rem;
  border-radius: 8px;
  border: 1px solid var(--border-strong);
  background: var(--surface-2);
  color: inherit;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 1.2rem;
}

.btn-nav:hover {
  background: var(--surface-3);
}

.loading {
  text-align: center;
  padding: 2rem;
  color: var(--text-muted);
}

.week-view {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 0.5rem;
  min-height: 500px;
}

.month-view {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.month-header {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 0.5rem;
}

.month-header-cell {
  text-align: center;
  font-size: 0.8rem;
  text-transform: uppercase;
  color: var(--text-muted);
  font-weight: 600;
}

.month-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 0.5rem;
}

.month-day {
  background: var(--surface-1);
  border-radius: 8px;
  padding: 0.5rem;
  border: 1px solid var(--border);
  min-height: 110px;
  cursor: pointer;
  transition: background 0.2s, border-color 0.2s;
  display: flex;
  flex-direction: column;
}

.month-day:hover {
  background: var(--surface-2);
}

.month-day.is-other-month {
  opacity: 0.45;
}

.month-day.is-selected {
  border-color: var(--primary);
  background: rgba(59, 130, 246, 0.08);
}

.month-day-number {
  font-weight: 700;
  margin-bottom: 0.4rem;
  font-size: 0.95rem;
}

.month-day-events {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  flex: 1;
}

.month-event-item {
  display: flex;
  flex-direction: column;
  padding: 0.3rem 0.4rem;
  border-radius: 4px;
  border-left: 3px solid;
  font-size: 0.75rem;
  line-height: 1.3;
  overflow: hidden;
}

.month-event-time {
  font-weight: 600;
  color: var(--text-muted-strong);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.month-event-title {
  color: var(--text);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.month-event-more {
  font-size: 0.75rem;
  color: var(--primary);
  font-weight: 600;
  padding: 0.25rem 0.4rem;
  text-align: center;
}

.month-day-empty {
  color: var(--text-faint);
  font-size: 0.75rem;
  text-align: center;
  padding: 0.5rem 0;
}

.list-view {
  display: flex;
  flex-direction: column;
}

.list-container {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.list-item {
  background: var(--surface-1);
  border: 1px solid var(--border);
  border-left: 4px solid;
  border-radius: 8px;
  padding: 1rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  transition: background 0.2s;
}

.list-item:hover {
  background: var(--surface-2);
}

.list-item-header {
  display: flex;
  gap: 1.5rem;
  align-items: center;
  flex: 1;
}

.list-item-date {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  min-width: 120px;
}

.list-date-day {
  font-weight: 700;
  font-size: 0.95rem;
  color: var(--text);
}

.list-date-time {
  font-size: 0.85rem;
  color: var(--text-muted);
}

.list-item-content {
  flex: 1;
}

.list-item-title {
  font-weight: 600;
  font-size: 1rem;
  margin-bottom: 0.25rem;
}

.list-item-description {
  font-size: 0.9rem;
  color: var(--text-muted);
  margin-top: 0.25rem;
}

.list-item-actions {
  display: flex;
  gap: 0.5rem;
  flex-shrink: 0;
}

.day-modal {
  position: fixed;
  inset: 0;
  z-index: 1200;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
}

.day-modal-backdrop {
  position: absolute;
  inset: 0;
  background: var(--bg-gradient);
}

.day-modal-content {
  position: relative;
  width: 100%;
  max-width: 640px;
  max-height: 85vh;
  overflow-y: auto;
  background: var(--surface-1);
  border: 1px solid var(--border);
  border-radius: 14px;
  padding: 1.25rem;
  z-index: 1;
}

.day-modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  margin-bottom: 1rem;
}

.day-modal-header h4 {
  margin: 0;
  font-size: 1rem;
}

.day-modal-header .btn-close {
  border: none;
  background: transparent;
  color: var(--text);
  cursor: pointer;
  font-size: 1.1rem;
}

.day-column {
  background: var(--surface-1);
  border-radius: 8px;
  overflow: hidden;
  border: 1px solid var(--border);
}

.day-header {
  background: var(--surface-2);
  padding: 0.75rem;
  text-align: center;
  border-bottom: 1px solid var(--border);
}

.day-name {
  font-size: 0.85rem;
  color: var(--text-muted);
  text-transform: uppercase;
  font-weight: 600;
}

.day-number {
  font-size: 1.5rem;
  font-weight: 700;
  margin-top: 0.25rem;
}

.day-bookings {
  padding: 0.5rem;
}

.booking-item {
  background: var(--surface-2);
  border-radius: 6px;
  padding: 0.75rem;
  margin-bottom: 0.5rem;
  border-left: 3px solid;
  position: relative;
}

.booking-time {
  font-size: 0.8rem;
  color: var(--text-muted);
  margin-bottom: 0.25rem;
}

.booking-title {
  font-weight: 600;
  margin-bottom: 0.25rem;
}

.booking-description {
  font-size: 0.85rem;
  color: var(--text-muted);
  margin-top: 0.5rem;
}

.btn-delete-small {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  padding: 0.25rem 0.5rem;
  border: none;
  background: var(--danger-bg);
  color: var(--danger);
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.85rem;
  opacity: 0;
  transition: opacity 0.2s;
}

.booking-item:hover .btn-delete-small {
  opacity: 1;
}

.booking-actions {
  display: flex;
  gap: 0.5rem;
  margin-top: 0.75rem;
}

.btn-small {
  padding: 0.35rem 0.6rem;
  font-size: 0.85rem;
}

.booking-edit .btn-delete-small {
  position: static;
  opacity: 1;
}

.day-modal .btn-delete-small {
  position: static;
  opacity: 1;
}

.day-modal .booking-item:hover .btn-delete-small {
  opacity: 1;
}

.no-bookings {
  text-align: center;
  padding: 2rem 0.5rem;
  color: var(--text-faint);
  font-size: 0.9rem;
}

@media (max-width: 1024px) {
  .week-view {
    grid-template-columns: repeat(4, 1fr);
  }

  .month-grid {
    grid-template-columns: repeat(4, 1fr);
  }
}

@media (max-width: 768px) {
  .week-view {
    grid-template-columns: repeat(2, 1fr);
  }

  .month-header,
  .month-grid {
    grid-template-columns: repeat(7, 1fr);
  }

  .month-header-cell {
    font-size: 0.65rem;
    padding: 0.25rem 0;
  }

  .month-day {
    min-height: 80px;
    padding: 0.25rem;
  }

  .month-day-number {
    font-size: 0.8rem;
    margin-bottom: 0.25rem;
  }

  .month-event-item {
    font-size: 0.65rem;
    padding: 0.2rem 0.25rem;
  }

  .month-event-time,
  .month-event-title {
    font-size: 0.65rem;
  }

  .month-event-more {
    font-size: 0.65rem;
    padding: 0.2rem 0.25rem;
  }

  .month-day-empty {
    font-size: 0.65rem;
    padding: 0.25rem 0;
  }

  .form-row {
    grid-template-columns: 1fr;
  }

  .list-item {
    flex-direction: column;
    align-items: flex-start;
  }

  .list-item-header {
    flex-direction: column;
    gap: 0.75rem;
    width: 100%;
  }

  .list-item-date {
    min-width: auto;
  }

  .list-item-actions {
    width: 100%;
    justify-content: flex-end;
  }
}
</style>
