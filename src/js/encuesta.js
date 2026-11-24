import { supabase } from "./supabaseClient.js";
import { calcularHuella } from "./calculo.js";
import { APP_CONFIG } from "./config.js";
import { mostrarMensaje } from "./ui.js";

const stepLabel = document.getElementById("wizard-step-label");
const progressBar = document.getElementById("wizard-progress-bar");
const huellaVivoEl = document.getElementById("huella-vivo");
const wizardBody = document.getElementById("wizard-body");
const btnAtras = document.getElementById("btn-atras");
const btnSiguiente = document.getElementById("btn-siguiente");
const estadoEl = document.getElementById("estado-encuesta");
const infoPeriodo = document.getElementById("info-periodo");

let contexto = { user: null, period: null, consent: null };
let pasoActual = 1;
const TOTAL_PASOS = 11;

const ELECTRODOMESTICOS = [
  { id: "nevera", nombre: "Nevera", emoji: "🧊", sub: "Siempre encendida", fijo: true, kwhMesBase: 36, tipoUso: "fijo" },
  { id: "aire", nombre: "Aire acondicionado", emoji: "❄️", kwhHora: 1.2, tipoUso: "dia" },
  { id: "ventilador", nombre: "Ventilador", emoji: "🌀", kwhHora: 0.065, tipoUso: "dia" },
  { id: "tv", nombre: "Televisor", emoji: "📺", kwhHora: 0.1, tipoUso: "dia" },
  { id: "bombillos", nombre: "Bombillos", emoji: "💡", kwhHora: 0.05, tipoUso: "dia" },
  { id: "portatil", nombre: "Portátil", emoji: "💻", kwhHora: 0.05, tipoUso: "dia" },
  { id: "pc", nombre: "PC de escritorio", emoji: "🖥️", kwhHora: 0.18, tipoUso: "dia" },
  { id: "microondas", nombre: "Microondas", emoji: "🍿", kwhHora: 1.1, tipoUso: "semana" },
  { id: "lavadora", nombre: "Lavadora", emoji: "🫧", kwhHora: 0.5, tipoUso: "semana" },
  { id: "plancha", nombre: "Plancha", emoji: "👕", kwhHora: 1.0, tipoUso: "semana" },
  { id: "horno", nombre: "Horno eléctrico", emoji: "🍕", kwhHora: 1.5, tipoUso: "semana" },
  { id: "secador", nombre: "Secador de pelo", emoji: "💇", kwhHora: 1.4, tipoUso: "semana" }
];

const OPCIONES_DIA = [
  { id: "menos_1", label: "Menos de 1 h", horas: 0.5 },
  { id: "1_3", label: "1 a 3 h", horas: 2 },
  { id: "3_6", label: "3 a 6 h", horas: 4.5 },
  { id: "6_10", label: "6 a 10 h", horas: 8 },
  { id: "mas_10", label: "Más de 10 h", horas: 12 }
];

const OPCIONES_SEMANA = [
  { id: "1h", label: "1 h", horas: 1 },
  { id: "2_3h", label: "2 a 3 h", horas: 2.5 },
  { id: "4_6h", label: "4 a 6 h", horas: 5 },
  { id: "mas_6h", label: "Más de 6 h", horas: 8 }
];

const state = {
  personas: 1,
  tieneRecibo: false,
  kwhReciboMes: 150,
  equiposSeleccionados: ["nevera", "ventilador", "tv", "bombillos", "portatil", "lavadora"],
  horasEquipos: {
    ventilador: "3_6",
    tv: "1_3",
    bombillos: "3_6",
    portatil: "3_6",
    lavadora: "2_3h"
  },
  cocina: "gas_natural",
  dieta: "omnivora",
  reciclaje: "aveces",
  transporte: "bus",
  distancia: "3_7",
  diasSemana: 5,
  viajoAvion: false,
  vuelosMes: 1
};

function calcularDesgloseMensual() {
  const FE_ELEC = 0.220; // kg CO2e / kWh (SIN Colombia UPME)
  const personas = Math.max(1, state.personas);

  // 1. Energia en casa (mensual por persona)
  let kwhTotalHogarMes = 0;
  const itemsDetalle = [];

  if (state.tieneRecibo) {
    kwhTotalHogarMes = Math.max(0, Number(state.kwhReciboMes) || 0);
    const kg = (kwhTotalHogarMes / personas) * FE_ELEC;
    itemsDetalle.push({ nombre: "Electricidad (recibo)", emoji: "⚡", kg, estimado: false });
  } else {
    for (const id of state.equiposSeleccionados) {
      const eq = ELECTRODOMESTICOS.find((e) => e.id === id);
      if (!eq) continue;
      let kwhEq = 0;
      if (eq.tipoUso === "fijo") {
        kwhEq = eq.kwhMesBase;
      } else if (eq.tipoUso === "dia") {
        const sel = OPCIONES_DIA.find((o) => o.id === (state.horasEquipos[id] || "1_3")) || OPCIONES_DIA[1];
        kwhEq = eq.kwhHora * sel.horas * 30;
      } else {
        const sel = OPCIONES_SEMANA.find((o) => o.id === (state.horasEquipos[id] || "1h")) || OPCIONES_SEMANA[0];
        kwhEq = eq.kwhHora * sel.horas * 4.33;
      }
      kwhTotalHogarMes += kwhEq;
      const kgEq = (kwhEq / personas) * FE_ELEC;
      itemsDetalle.push({ nombre: eq.nombre, emoji: eq.emoji, kg: kgEq, estimado: true });
    }
  }

  const energiaKgMes = (kwhTotalHogarMes / personas) * FE_ELEC;

  // 2. Cocina (mensual por persona)
  const cocinaMap = {
    gas_natural: { kgHogar: 18.5, m3HogarMes: 9.5 },
    pipeta: { kgHogar: 22.0, m3HogarMes: 11.0 },
    electrica: { kgHogar: 14.0, m3HogarMes: 7.0 },
    lena: { kgHogar: 35.0, m3HogarMes: 18.0 },
    no_cocina: { kgHogar: 0, m3HogarMes: 0 }
  };
  const coc = cocinaMap[state.cocina] || cocinaMap.gas_natural;
  const cocinaKgMes = coc.kgHogar / personas;
  if (cocinaKgMes > 0) {
    itemsDetalle.push({ nombre: "Cocina", emoji: "🍳", kg: cocinaKgMes, estimado: true });
  }

  // 3. Consumo y residuos (mensual)
  const dietaKgMes = state.dieta === "vegana" ? 18 : state.dieta === "poca_carne" ? 32 : 48;
  const residuosKgMes = state.reciclaje === "siempre" ? 4 : state.reciclaje === "aveces" ? 8 : 13;
  itemsDetalle.push({ nombre: "Alimentación y consumo", emoji: "🥗", kg: dietaKgMes, estimado: true });
  itemsDetalle.push({ nombre: "Residuos del hogar", emoji: "♻️", kg: residuosKgMes, estimado: true });

  // 4. Movilidad a la universidad (mensual)
  const distKmIdaMap = { menos_1: 0.7, "1_3": 2, "3_7": 5, "7_15": 11, mas_15: 20 };
  const kmIda = distKmIdaMap[state.distancia] || 5;
  const kmMes = kmIda * 2 * state.diasSemana * 4.33;

  const transpConfig = {
    pie: { fe: 0, code: "TRANSP_BICI_PIE" },
    bicicleta: { fe: 0, code: "TRANSP_BICI_PIE" },
    bus: { fe: 0.089, code: "TRANSP_BUS_CO" },
    moto: { fe: 0.103, code: "TRANSP_MOTO_CO" },
    mototaxi: { fe: 0.115, code: "TRANSP_MOTO_CO" },
    carro: { fe: 0.192, code: "TRANSP_AUTO_CO" },
    taxi: { fe: 0.210, code: "TRANSP_AUTO_CO" }
  };
  const tr = transpConfig[state.transporte] || transpConfig.bus;
  const movilidadKgMes = kmMes * tr.fe;
  itemsDetalle.push({ nombre: "Ida y vuelta a la U", emoji: "🚌", kg: movilidadKgMes, estimado: false });

  // 5. Vuelos (mensual)
  const vuelosKgMes = state.viajoAvion ? Math.max(1, Number(state.vuelosMes) || 1) * 115 : 0;
  if (vuelosKgMes > 0) {
    itemsDetalle.push({ nombre: "Vuelos del mes", emoji: "✈️", kg: vuelosKgMes, estimado: true });
  }

  const totalKgMes = energiaKgMes + cocinaKgMes + dietaKgMes + residuosKgMes + movilidadKgMes + vuelosKgMes;

  return {
    totalKgMes,
    energiaKgMes,
    cocinaKgMes,
    movilidadKgMes,
    consumoResiduosKgMes: dietaKgMes + residuosKgMes,
    vuelosKgMes,
    kwhAnualHogar: kwhTotalHogarMes * 12,
    gasM3AnualHogar: coc.m3HogarMes * 12,
    kmAnual: kmMes * 12,
    transporteCode: tr.code,
    itemsDetalle: itemsDetalle.sort((a, b) => b.kg - a.kg)
  };
}

function actualizarPillEnVivo() {
  const res = calcularDesgloseMensual();
  const formatted = res.totalKgMes.toFixed(1).replace(".", ",");
  if (huellaVivoEl) huellaVivoEl.textContent = `${formatted} kg CO₂e`;
}

function renderPaso() {
  actualizarPillEnVivo();
  progressBar.style.width = `${Math.round((pasoActual / TOTAL_PASOS) * 100)}%`;
  btnAtras.disabled = pasoActual === 1;
  btnSiguiente.textContent = pasoActual === TOTAL_PASOS ? "Ver mi huella 🌱" : "Siguiente →";

  // Si tiene recibo, saltar pasos 3 y 4 de electrodomesticos
  if (pasoActual === 1) {
    stepLabel.textContent = "TU CASA · 1 DE 11";
    wizardBody.innerHTML = `
      <h2 class="wizard-title">¿Cuántas personas viven en tu casa?</h2>
      <p class="wizard-subtitle">Contándote a ti. Así repartimos el consumo de la casa entre todos.</p>
      <div class="stepper-box">
        <button type="button" class="btn-circle" id="btn-menos">−</button>
        <span class="stepper-val" id="val-personas">${state.personas}</span>
        <button type="button" class="btn-circle" id="btn-mas">+</button>
      </div>
    `;
    document.getElementById("btn-menos").onclick = () => {
      if (state.personas > 1) { state.personas--; renderPaso(); }
    };
    document.getElementById("btn-mas").onclick = () => {
      if (state.personas < 20) { state.personas++; renderPaso(); }
    };
  }

  else if (pasoActual === 2) {
    stepLabel.textContent = "ENERGÍA · 2 DE 11";
    wizardBody.innerHTML = `
      <h2 class="wizard-title">¿Tienes a mano el recibo de luz?</h2>
      <p class="wizard-subtitle">Si no, no pasa nada: lo calculamos con tus electrodomésticos.</p>
      <div class="cards-grid cards-grid-2">
        <div class="option-card ${state.tieneRecibo ? "selected" : ""}" data-recibo="true">
          <span class="option-emoji">🧾</span>
          <span class="option-label">Sí, lo tengo</span>
        </div>
        <div class="option-card ${!state.tieneRecibo ? "selected" : ""}" data-recibo="false">
          <span class="option-emoji">🤷</span>
          <span class="option-label">No lo tengo</span>
        </div>
      </div>
      ${state.tieneRecibo ? `
        <div class="inline-input-box">
          <label for="input-kwh-mes">Consumo mensual del recibo (kWh/mes)</label>
          <input id="input-kwh-mes" type="number" min="1" step="1" value="${state.kwhReciboMes}">
        </div>
      ` : ""}
    `;
    wizardBody.querySelectorAll("[data-recibo]").forEach((el) => {
      el.onclick = () => {
        state.tieneRecibo = el.dataset.recibo === "true";
        renderPaso();
      };
    });
    const inpKwh = document.getElementById("input-kwh-mes");
    if (inpKwh) {
      inpKwh.oninput = () => {
        state.kwhReciboMes = Number(inpKwh.value) || 0;
        actualizarPillEnVivo();
      };
    }
  }

  else if (pasoActual === 3) {
    stepLabel.textContent = "ENERGÍA · 3 DE 11";
    wizardBody.innerHTML = `
      <h2 class="wizard-title">¿Cuáles de estos hay en tu casa?</h2>
      <p class="wizard-subtitle">Toca todos los que tengan. Puedes elegir varios.</p>
      <div class="cards-grid">
        ${ELECTRODOMESTICOS.map((eq) => {
          const sel = state.equiposSeleccionados.includes(eq.id);
          return `
            <div class="option-card ${sel ? "selected" : ""}" data-eq="${eq.id}">
              <span class="option-emoji">${eq.emoji}</span>
              <span class="option-label">${eq.nombre}</span>
              ${eq.sub ? `<span class="option-sub">${eq.sub}</span>` : ""}
            </div>
          `;
        }).join("")}
      </div>
    `;
    wizardBody.querySelectorAll("[data-eq]").forEach((el) => {
      el.onclick = () => {
        const id = el.dataset.eq;
        if (id === "nevera") return;
        if (state.equiposSeleccionados.includes(id)) {
          state.equiposSeleccionados = state.equiposSeleccionados.filter((x) => x !== id);
        } else {
          state.equiposSeleccionados.push(id);
          if (!state.horasEquipos[id]) {
            const eq = ELECTRODOMESTICOS.find((e) => e.id === id);
            state.horasEquipos[id] = eq?.tipoUso === "dia" ? "1_3" : "1h";
          }
        }
        renderPaso();
      };
    });
  }

  else if (pasoActual === 4) {
    stepLabel.textContent = "ENERGÍA · 4 DE 11";
    const activos = ELECTRODOMESTICOS.filter((e) => !e.fijo && state.equiposSeleccionados.includes(e.id));
    wizardBody.innerHTML = `
      <h2 class="wizard-title">¿Cuánto tiempo los usan?</h2>
      <p class="wizard-subtitle">Un promedio está bien. La nevera ya la contamos encendida todo el día.</p>
      ${activos.length === 0 ? `<p class="wizard-subtitle">No seleccionaste electrodomésticos adicionales.</p>` : ""}
      ${activos.map((eq) => {
        const opts = eq.tipoUso === "dia" ? OPCIONES_DIA : OPCIONES_SEMANA;
        const unitLabel = eq.tipoUso === "dia" ? "horas al día" : "horas a la semana";
        const valActual = state.horasEquipos[eq.id] || opts[0].id;
        return `
          <div class="appliance-time-row">
            <div class="appliance-time-title">
              <span>${eq.emoji}</span>
              <span>${eq.nombre}</span>
              <span class="appliance-time-unit">${unitLabel}</span>
            </div>
            <div class="pills-row">
              ${opts.map((o) => `
                <button type="button" class="pill-btn ${valActual === o.id ? "selected" : ""}" data-eq-hora="${eq.id}" data-val="${o.id}">${o.label}</button>
              `).join("")}
            </div>
          </div>
        `;
      }).join("")}
      <div class="did-you-know">
        <strong>¿Sabías que...?</strong> Una hora de aire acondicionado gasta lo mismo que unas 11 horas de ventilador.
      </div>
    `;
    wizardBody.querySelectorAll("[data-eq-hora]").forEach((btn) => {
      btn.onclick = () => {
        state.horasEquipos[btn.dataset.eqHora] = btn.dataset.val;
        renderPaso();
      };
    });
  }

  else if (pasoActual === 5) {
    stepLabel.textContent = "COCINA · 5 DE 11";
    const opcionesCocina = [
      { id: "gas_natural", label: "Gas natural", sub: "Llega por tubería", emoji: "🔥" },
      { id: "pipeta", label: "Pipeta", sub: "Gas en cilindro", emoji: "🛢️" },
      { id: "electrica", label: "Estufa eléctrica", sub: "Se enchufa", emoji: "⚡" },
      { id: "lena", label: "Leña o carbón", sub: "Combustible sólido", emoji: "🪵" },
      { id: "no_cocina", label: "No cocinamos", sub: "Compramos hecho", emoji: "🥡" }
    ];
    wizardBody.innerHTML = `
      <h2 class="wizard-title">¿Con qué cocinan en tu casa?</h2>
      <p class="wizard-subtitle">Elige el que más usan.</p>
      <div class="cards-grid">
        ${opcionesCocina.map((c) => `
          <div class="option-card ${state.cocina === c.id ? "selected" : ""}" data-cocina="${c.id}">
            <span class="option-emoji">${c.emoji}</span>
            <span class="option-label">${c.label}</span>
            <span class="option-sub">${c.sub}</span>
          </div>
        `).join("")}
      </div>
    `;
    wizardBody.querySelectorAll("[data-cocina]").forEach((el) => {
      el.onclick = () => { state.cocina = el.dataset.cocina; renderPaso(); };
    });
  }

  else if (pasoActual === 6) {
    stepLabel.textContent = "CONSUMO · 6 DE 11";
    const dietas = [
      { id: "omnivora", label: "De todo un poco", sub: "Carne frecuente", emoji: "🥩" },
      { id: "poca_carne", label: "Poca carne roja", sub: "Pollo, pescado o granos", emoji: "🍗" },
      { id: "vegana", label: "Vegetariana / Vegana", sub: "Basada en plantas", emoji: "🥗" }
    ];
    wizardBody.innerHTML = `
      <h2 class="wizard-title">¿Cómo es tu alimentación habitual?</h2>
      <p class="wizard-subtitle">La producción de alimentos también representa parte de tu huella mensual.</p>
      <div class="cards-grid">
        ${dietas.map((d) => `
          <div class="option-card ${state.dieta === d.id ? "selected" : ""}" data-dieta="${d.id}">
            <span class="option-emoji">${d.emoji}</span>
            <span class="option-label">${d.label}</span>
            <span class="option-sub">${d.sub}</span>
          </div>
        `).join("")}
      </div>
    `;
    wizardBody.querySelectorAll("[data-dieta]").forEach((el) => {
      el.onclick = () => { state.dieta = el.dataset.dieta; renderPaso(); };
    });
  }

  else if (pasoActual === 7) {
    stepLabel.textContent = "RESIDUOS · 7 DE 11";
    const optsRec = [
      { id: "nunca", label: "No separo", sub: "Todo en una bolsa", emoji: "🗑️" },
      { id: "aveces", label: "Separo a veces", sub: "Plástico y cartón", emoji: "♻️" },
      { id: "siempre", label: "Reciclo y compuesto", sub: "Separación completa", emoji: "🌱" }
    ];
    wizardBody.innerHTML = `
      <h2 class="wizard-title">¿Separas los residuos en tu casa?</h2>
      <p class="wizard-subtitle">Separar aprovechables reduce las emisiones en relleno sanitario.</p>
      <div class="cards-grid">
        ${optsRec.map((r) => `
          <div class="option-card ${state.reciclaje === r.id ? "selected" : ""}" data-rec="${r.id}">
            <span class="option-emoji">${r.emoji}</span>
            <span class="option-label">${r.label}</span>
            <span class="option-sub">${r.sub}</span>
          </div>
        `).join("")}
      </div>
    `;
    wizardBody.querySelectorAll("[data-rec]").forEach((el) => {
      el.onclick = () => { state.reciclaje = el.dataset.rec; renderPaso(); };
    });
  }

  else if (pasoActual === 8) {
    stepLabel.textContent = "MOVILIDAD · 8 DE 11";
    const medios = [
      { id: "pie", label: "A pie", emoji: "🚶" },
      { id: "bicicleta", label: "Bicicleta", emoji: "🚲" },
      { id: "bus", label: "Bus o buseta", emoji: "🚌" },
      { id: "moto", label: "Moto propia", emoji: "🏍️" },
      { id: "mototaxi", label: "Mototaxi", emoji: "🛵" },
      { id: "carro", label: "Carro", emoji: "🚗" },
      { id: "taxi", label: "Taxi o plataforma", emoji: "🚕" }
    ];
    wizardBody.innerHTML = `
      <h2 class="wizard-title">¿Cómo llegas normalmente a la universidad?</h2>
      <p class="wizard-subtitle">El medio en el que haces la mayor parte del camino.</p>
      <div class="cards-grid">
        ${medios.map((m) => `
          <div class="option-card ${state.transporte === m.id ? "selected" : ""}" data-transp="${m.id}">
            <span class="option-emoji">${m.emoji}</span>
            <span class="option-label">${m.label}</span>
          </div>
        `).join("")}
      </div>
    `;
    wizardBody.querySelectorAll("[data-transp]").forEach((el) => {
      el.onclick = () => { state.transporte = el.dataset.transp; renderPaso(); };
    });
  }

  else if (pasoActual === 9) {
    stepLabel.textContent = "MOVILIDAD · 9 DE 11";
    const distancias = [
      { id: "menos_1", label: "Menos de 1 km" },
      { id: "1_3", label: "1 a 3 km" },
      { id: "3_7", label: "3 a 7 km" },
      { id: "7_15", label: "7 a 15 km" },
      { id: "mas_15", label: "Más de 15 km" }
    ];
    wizardBody.innerHTML = `
      <h2 class="wizard-title">¿A qué distancia vives de la universidad?</h2>
      <p class="wizard-subtitle">Solo de ida. Un cálculo aproximado está bien.</p>
      <div class="pills-row" style="margin: 1.25rem 0 1.5rem 0;">
        ${distancias.map((d) => `
          <button type="button" class="pill-btn ${state.distancia === d.id ? "selected" : ""}" data-dist="${d.id}">${d.label}</button>
        `).join("")}
      </div>
    `;
    wizardBody.querySelectorAll("[data-dist]").forEach((btn) => {
      btn.onclick = () => { state.distancia = btn.dataset.dist; renderPaso(); };
    });
  }

  else if (pasoActual === 10) {
    stepLabel.textContent = "MOVILIDAD · 10 DE 11";
    wizardBody.innerHTML = `
      <h2 class="wizard-title">¿Cuántos días a la semana vas?</h2>
      <p class="wizard-subtitle">Selecciona los días habituales de asistencia al campus.</p>
      <div class="days-row">
        ${[1, 2, 3, 4, 5, 6, 7].map((d) => `
          <button type="button" class="day-circle ${state.diasSemana === d ? "selected" : ""}" data-dia="${d}">${d}</button>
        `).join("")}
      </div>
    `;
    wizardBody.querySelectorAll("[data-dia]").forEach((btn) => {
      btn.onclick = () => { state.diasSemana = Number(btn.dataset.dia); renderPaso(); };
    });
  }

  else if (pasoActual === 11) {
    stepLabel.textContent = "VUELOS · 11 DE 11";
    wizardBody.innerHTML = `
      <h2 class="wizard-title">¿Viajaste en avión este mes?</h2>
      <p class="wizard-subtitle">Cuenta vuelos nacionales o internacionales de ida y vuelta.</p>
      <div class="cards-grid cards-grid-2">
        <div class="option-card ${state.viajoAvion ? "selected" : ""}" data-avion="true">
          <span class="option-emoji">✈️</span>
          <span class="option-label">Sí</span>
        </div>
        <div class="option-card ${!state.viajoAvion ? "selected" : ""}" data-avion="false">
          <span class="option-emoji">🏠</span>
          <span class="option-label">No</span>
        </div>
      </div>
      ${state.viajoAvion ? `
        <div class="inline-input-box">
          <label for="input-vuelos">Número de trayectos en avión este mes</label>
          <input id="input-vuelos" type="number" min="1" max="30" value="${state.vuelosMes}">
        </div>
      ` : ""}
    `;
    wizardBody.querySelectorAll("[data-avion]").forEach((el) => {
      el.onclick = () => { state.viajoAvion = el.dataset.avion === "true"; renderPaso(); };
    });
    const inpVuelos = document.getElementById("input-vuelos");
    if (inpVuelos) {
      inpVuelos.oninput = () => {
        state.vuelosMes = Number(inpVuelos.value) || 1;
        actualizarPillEnVivo();
      };
    }
  }
}

btnAtras.addEventListener("click", () => {
  if (pasoActual === 5 && state.tieneRecibo) {
    pasoActual = 2;
  } else if (pasoActual > 1) {
    pasoActual--;
  }
  renderPaso();
});

btnSiguiente.addEventListener("click", async () => {
  if (pasoActual === 2 && state.tieneRecibo) {
    pasoActual = 5;
    renderPaso();
    return;
  }
  if (pasoActual < TOTAL_PASOS) {
    pasoActual++;
    renderPaso();
    return;
  }
  await enviarEncuesta();
});

async function enviarEncuesta() {
  try {
    btnSiguiente.disabled = true;
    btnSiguiente.textContent = "Calculando...";
    const desglose = calcularDesgloseMensual();

    // Guardar resumen visual en localStorage para la pantalla de resultados estilo tarjeta
    localStorage.setItem("huellaviva_ultimo_resultado", JSON.stringify({
      fecha: new Date().toISOString(),
      state,
      desglose
    }));

    if (!contexto.user || !contexto.period || !contexto.consent) {
      window.location.href = "./informe.html";
      return;
    }

    const { data: survey, error: errSurvey } = await supabase
      .from("surveys")
      .upsert({
        user_id: contexto.user.id,
        period_id: contexto.period.id,
        consent_id: contexto.consent.id,
        status: "enviada",
        submitted_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      }, { onConflict: "user_id,period_id" })
      .select()
      .single();

    if (errSurvey) throw errSurvey;

    await supabase.from("activity_answers").delete().eq("survey_id", survey.id);

    const filasRespuestas = [
      { survey_id: survey.id, category: "electricidad", question_code: "PERSONAS_HOGAR", numeric_value: state.personas, unit: "personas", is_estimated: false },
      { survey_id: survey.id, category: "electricidad", question_code: "ELEC_SIN_CO", numeric_value: Number(desglose.kwhAnualHogar.toFixed(2)), unit: "kWh", is_estimated: !state.tieneRecibo },
      { survey_id: survey.id, category: "desplazamiento_campus", question_code: desglose.transporteCode, numeric_value: Number(desglose.kmAnual.toFixed(2)), unit: "km", is_estimated: true }
    ];

    if (desglose.gasM3AnualHogar > 0) {
      filasRespuestas.push({
        survey_id: survey.id,
        category: "gas_combustibles",
        question_code: "GAS_NAT_CO",
        numeric_value: Number(desglose.gasM3AnualHogar.toFixed(2)),
        unit: "m3",
        is_estimated: true
      });
    }

    const { data: savedAnswers, error: errAns } = await supabase.from("activity_answers").insert(filasRespuestas).select();
    if (errAns) throw errAns;

    const { data: factors } = await supabase.from("emission_factors").select("*").eq("is_active", true);
    const factorsMap = new Map((factors || []).map((f) => [f.factor_code, f]));

    const inputsCalculo = (savedAnswers || [])
      .filter((a) => a.question_code !== "PERSONAS_HOGAR")
      .map((a) => ({ ...a, factor_code: a.question_code }));

    const resultado = calcularHuella(inputsCalculo, factorsMap, { householdSize: state.personas });

    const { data: calc, error: errCalc } = await supabase
      .from("calculations")
      .insert({
        survey_id: survey.id,
        method_version: APP_CONFIG.METHOD_VERSION,
        total_kgco2e: resultado.total_kgco2e,
        has_estimated_inputs: resultado.has_estimated_inputs,
        excluded_categories: resultado.excluded_categories
      })
      .select()
      .single();

    if (!errCalc && calc && resultado.details.length > 0) {
      const detalles = resultado.details.map((d) => ({
        calculation_id: calc.id,
        answer_id: d.answer_id,
        factor_id: d.factor_id,
        category: d.category,
        activity_value: d.activity_value,
        converted_value: d.converted_value,
        emissions_kgco2e: d.emissions_kgco2e
      }));
      await supabase.from("calculation_details").insert(detalles);
    }

    window.location.href = "./informe.html";
  } catch (err) {
    btnSiguiente.disabled = false;
    btnSiguiente.textContent = "Ver mi huella 🌱";
    mostrarMensaje(estadoEl, `Error al guardar: ${err.message}`, "error");
  }
}

async function inicializar() {
  renderPaso();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    window.location.href = "./login.html";
    return;
  }
  const { data: consent } = await supabase
    .from("consents")
    .select("id")
    .eq("user_id", user.id)
    .is("revoked_at", null)
    .limit(1)
    .maybeSingle();

  if (!consent) {
    window.location.href = "./consentimiento.html";
    return;
  }

  const { data: period } = await supabase
    .from("survey_periods")
    .select("*")
    .eq("is_open", true)
    .limit(1)
    .maybeSingle();

  if (!period) {
    if (infoPeriodo) infoPeriodo.textContent = "No hay periodos abiertos actualmente.";
    return;
  }

  contexto = { user, period, consent };
  if (infoPeriodo) infoPeriodo.textContent = `Periodo activo: ${period.name} (${period.code})`;
}

inicializar();