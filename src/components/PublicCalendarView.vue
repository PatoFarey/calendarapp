<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase, type Calendar, type Booking } from '../lib/supabase'

const props = defineProps<{
  calendarId: string
}>()

const calendar = ref<Calendar | null>(null)
const bookings = ref<Booking[]>([])
const loading = ref(true)
const errorMessage = ref('')
const currentMonth = ref(new Date())
const currentMonthDates = ref<Date[]>([])
const selectedDate = ref(new Date())
const showDayModal = ref(false)

const formatMonthTitle = (date: Date) => {
  return date.toLocaleDateString('es-ES', { month: 'long', year: 'numeric' })
}

const formatTime = (date: string) => {
  return new Date(date).toLocaleTimeString('es-ES', {
    hour: '2-digit',
    minute: '2-digit'
  })
}

const formatDateFromDate = (date: Date) => {
  return date.toLocaleDateString('es-ES', {
    day: 'numeric',
    month: 'short'
  })
}

const goToApp = () => {
  window.location.href = `${window.location.origin}/`
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

const isSameMonth = (date: Date) => {
  return date.getMonth() === currentMonth.value.getMonth() &&
    date.getFullYear() === currentMonth.value.getFullYear()
}

const bookingsForDate = (date: Date) => {
  const dayDate = new Date(date.getFullYear(), date.getMonth(), date.getDate())

  return bookings.value.filter(b => {
    const startDate = new Date(b.start_time)
    const endDate = new Date(b.end_time)
    const startDateOnly = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate())
    const endDateOnly = new Date(endDate.getFullYear(), endDate.getMonth(), endDate.getDate())

    return dayDate >= startDateOnly && dayDate <= endDateOnly
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
}

const previousMonth = () => {
  currentMonth.value = new Date(currentMonth.value.getFullYear(), currentMonth.value.getMonth() - 1, 1)
  currentMonthDates.value = getMonthDates(currentMonth.value)
}

const nextMonth = () => {
  currentMonth.value = new Date(currentMonth.value.getFullYear(), currentMonth.value.getMonth() + 1, 1)
  currentMonthDates.value = getMonthDates(currentMonth.value)
}

const loadCalendar = async () => {
  const { data, error } = await supabase
    .from('calendars')
    .select('*')
    .eq('id', props.calendarId)
    .maybeSingle()

  if (error) throw error
  calendar.value = data
}

const loadBookings = async () => {
  const { data, error } = await supabase
    .from('bookings')
    .select('*')
    .eq('calendar_id', props.calendarId)
    .order('start_time', { ascending: true })

  if (error) throw error
  bookings.value = data || []
}

onMounted(async () => {
  loading.value = true
  try {
    await loadCalendar()
    if (!calendar.value) {
      errorMessage.value = 'Calendario no disponible'
      return
    }
    await loadBookings()
    currentMonthDates.value = getMonthDates(currentMonth.value)
  } catch (error) {
    console.error('Error loading public calendar:', error)
    errorMessage.value = 'No se pudo cargar el calendario'
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="public-calendar">
    <div class="public-header">
      <h2>{{ calendar?.name || 'Calendario' }}</h2>
      <button class="btn-cta" @click="goToApp">Crea tu calendario</button>
    </div>

    <div class="month-navigation">
      <button @click="previousMonth" class="btn-nav">←</button>
      <h3>{{ formatMonthTitle(currentMonth) }}</h3>
      <button @click="nextMonth" class="btn-nav">→</button>
    </div>

    <div v-if="loading" class="loading">Cargando calendario...</div>
    <div v-else-if="errorMessage" class="loading">{{ errorMessage }}</div>

    <div v-else class="month-view">
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
            'has-bookings': bookingsForDate(day).length > 0
          }"
          @click="handleDayClick(day)"
        >
          <div class="month-day-number">{{ day.getDate() }}</div>
          <div class="month-day-count">
            <span v-if="bookingsForDate(day).length > 0">
              {{ bookingsForDate(day).length }} eventos
            </span>
            <span v-else class="month-day-empty">Sin eventos</span>
          </div>
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
      <div v-if="bookingsForDate(selectedDate).length === 0" class="loading">
        Sin eventos
      </div>
      <div
        v-for="booking in bookingsForDate(selectedDate)"
        :key="booking.id"
        class="booking-item"
      >
        <div class="booking-time">
          {{ formatTime(booking.start_time) }} - {{ formatTime(booking.end_time) }}
        </div>
        <div class="booking-title">{{ booking.title }}</div>
        <div v-if="booking.description" class="booking-description">
          {{ booking.description }}
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.public-calendar {
  padding: 1.5rem;
  max-width: 1200px;
  margin: 0 auto;
}

.public-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 1rem;
  gap: 1rem;
  flex-wrap: wrap;
}

.public-header h2 {
  margin: 0;
  font-size: 2rem;
}

.btn-cta {
  padding: 0.6rem 1.1rem;
  border-radius: 999px;
  border: 1px solid var(--border-strong);
  background: var(--primary);
  color: white;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-cta:hover {
  background: var(--primary-hover);
}

.month-navigation {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 2rem;
  margin-bottom: 1.5rem;
}

.month-navigation h3 {
  margin: 0;
  font-size: 1.2rem;
  text-transform: capitalize;
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
  padding: 0.75rem;
  border: 1px solid var(--border);
  min-height: 110px;
}

.month-day.is-other-month {
  opacity: 0.45;
}

.month-day.has-bookings {
  background: var(--danger-bg);
  border-color: var(--danger);
}

.month-day-number {
  font-weight: 700;
  margin-bottom: 0.5rem;
}

.month-day-count {
  font-size: 0.85rem;
  color: var(--text-muted-strong);
}

.month-day-empty {
  color: var(--text-faint);
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
  background: var(--surface-solid);
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

.booking-item {
  background: var(--surface-2);
  border-radius: 6px;
  padding: 0.75rem;
  margin-bottom: 0.5rem;
  border-left: 3px solid var(--danger);
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

@media (max-width: 1024px) {
  .month-grid {
    grid-template-columns: repeat(4, 1fr);
  }
}

@media (max-width: 768px) {
  .month-header,
  .month-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>

