import { supabase } from "./supabaseClient.js";

const container = document.getElementById("informe-container");

function formatComma(num, dec = 1) {
  return Number(num || 0).toFixed(dec).replace(".", ",");
}

function obtenerMesAnioActual() {
  const meses = [
    "Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
    "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"
  ];
  const d = new Date();
  return `${meses[d.getMonth()]} ${d.getFullYear()}`;
}

function generarReto(mayorCategoria, state) {
  if (mayorCategoria === "movilidad") {
    if (state && (state.distancia === "menos_1" || state.distancia === "1_3")) {
      return "Si vives a menos de 3 km, prueba ir a pie o en bicicleta 1 día a la semana: son kilómetros con cero emisiones.";
    }
    return "Compartir vehículo o usar transporte público un día adicional a la semana puede reducir hasta un 20 % tus emisiones de movilidad.";
  }
  if (mayorCategoria === "energia") {
    return "Desconectar cargadores en reposo y limitar el uso de aire acondicionado o secador de pelo reduce notablemente tu consumo eléctrico mensual.";
  }
  if (mayorCategoria === "cocina") {
    return "Tapar las ollas al cocinar y optimizar los tiempos de cocción disminuye el consumo de combustible doméstico.";
  }
  return "Reducir el consumo de carnes rojas un día a la semana y separar los residuos aprovechables baja tu huella mensual de forma sostenida.";
}

async function cargarInforme() {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    window.location.href = "./login.html";
    return;
  }

  // Cargar datos visuales guardados desde el asistente de 11 pasos
  let localData = null;
  try {
    localData = JSON.parse(localStorage.getItem("huellaviva_ultimo_resultado"));
  } catch {}

  // Cargar ultimo calculo oficial guardado en Supabase
  const { data: surveys } = await supabase
    .from("surveys")
    .select("id, submitted_at")
    .eq("user_id", user.id)
    .order("submitted_at", { ascending: false })
    .limit(1);

  let calc = null;
  let details = [];

  if (surveys && surveys.length > 0) {
    const { data: calcs } = await supabase
      .from("calculations")
      .select("*")
      .eq("survey_id", surveys[0].id)
      .order("created_at", { ascending: false })
      .limit(1);

    if (calcs && calcs.length > 0) {
      calc = calcs[0];
      const { data: dets } = await supabase
        .from("calculation_details")
        .select("*, emission_factors(source_name, value, version)")
        .eq("calculation_id", calc.id);
      details = dets || [];
    }
  }

  if (!localData && !calc) {
    container.innerHTML = `
      <div class="box-card">
        <h2>Aún no tienes un cálculo registrado</h2>
        <p>Completa la encuesta de 11 pasos para estimar tu huella de carbono personal.</p>
        <a href="./encuesta.html" class="btn-outline-green">Ir a la encuesta →</a>
      </div>
    `;
    return;
  }

  // Preparar metricas visuales mensuales
  const desglose = localData?.desglose || {
    totalKgMes: calc ? Number(calc.total_kgco2e) / 12 : 0,
    movilidadKgMes: 0,
    energiaKgMes: 0,
    cocinaKgMes: 0,
    consumoResiduosKgMes: 0,
    vuelosKgMes: 0,
    itemsDetalle: []
  };

  const totalMes = desglose.totalKgMes;
  const kmCarroEq = Math.round(totalMes / 0.222); // ~222 g CO2/km carro gasolina promedio
  const tieneEstimados = localData ? !localData.state?.tieneRecibo : Boolean(calc?.has_estimated_inputs);

  // Construir barras horizontales de categorias principales
  const categoriasBarra = [
    { key: "movilidad", label: "🚌 Movilidad", val: desglose.movilidadKgMes },
    { key: "energia", label: "⚡ Energía en casa", val: desglose.energiaKgMes },
    { key: "cocina", label: "🍳 Cocina", val: desglose.cocinaKgMes },
    { key: "consumo", label: "🥗 Consumo y residuos", val: desglose.consumoResiduosKgMes }
  ];
  if (desglose.vuelosKgMes > 0) {
    categoriasBarra.push({ key: "vuelos", label: "✈️ Vuelos", val: desglose.vuelosKgMes });
  }

  const maxCat = Math.max(...categoriasBarra.map((c) => c.val), 1);
  const mayorCatObj = [...categoriasBarra].sort((a, b) => b.val - a.val)[0];
  const nombreMayor = mayorCatObj.key === "movilidad" ? "movilidad"
    : mayorCatObj.key === "energia" ? "energía en casa"
    : mayorCatObj.key === "cocina" ? "cocina"
    : mayorCatObj.key === "vuelos" ? "vuelos"
    : "consumo y residuos";

  const filasDetalle = (desglose.itemsDetalle || [])
    .filter((item) => item.kg > 0.01)
    .map((item) => `
      <tr>
        <td>
          <span>${item.emoji} ${item.nombre}</span>
          ${item.estimado ? `<span class="tag-estimado">estimado</span>` : ""}
        </td>
        <td><strong>${formatComma(item.kg, 1)}</strong></td>
      </tr>
    `).join("");

  const tablaOficialUpme = calc ? `
    <p><strong>Huella anual registrada en base de datos:</strong> ${Number(calc.total_kgco2e).toFixed(4)} kg CO₂e (${(Number(calc.total_kgco2e) / 1000).toFixed(4)} t CO₂e/año) · Método <code>${calc.method_version}</code></p>
    <div style="overflow-x:auto; margin-top:0.75rem;">
      <table class="detail-table">
        <thead>
          <tr>
            <th>Categoría</th>
            <th>Actividad anual</th>
            <th>Factor</th>
            <th>Emisiones (kg CO₂e)</th>
            <th>Fuente oficial</th>
          </tr>
        </thead>
        <tbody>
          ${details.map((d) => `
            <tr>
              <td>${d.category}</td>
              <td>${d.converted_value}</td>
              <td>${d.emission_factors?.value ?? "-"}</td>
              <td><strong>${Number(d.emissions_kgco2e).toFixed(4)}</strong></td>
              <td>${d.emission_factors?.source_name ?? "UPME Colombia"}</td>
            </tr>
          `).join("")}
        </tbody>
      </table>
    </div>
  ` : `<p>Cálculo estimado con factores de emisión académicos UPME Colombia (SIN 2024).</p>`;

  container.innerHTML = `
    <section class="hero-card">
      <p class="hero-subtitle-top">${obtenerMesAnioActual()} · tu huella del mes</p>
      <div class="hero-number">${formatComma(totalMes, 1)} <span class="hero-unit">kg CO₂e</span></div>
      <p class="hero-eq">Es lo que emite un carro a gasolina recorriendo unos <strong>${kmCarroEq} km</strong>.</p>
      ${tieneEstimados ? `<div class="hero-badge">Incluye estimaciones con valores típicos (no tenías el recibo)</div>` : ""}
    </section>

    <section class="box-card">
      <h2 class="box-title">¿De dónde sale?</h2>
      ${categoriasBarra.map((c) => {
        const pct = Math.max(4, Math.round((c.val / maxCat) * 100));
        return `
          <div class="bar-row">
            <div class="bar-label">${c.label}</div>
            <div class="bar-track"><div class="bar-fill" style="width:${pct}%"></div></div>
            <div class="bar-val">${formatComma(c.val, 1)} kg</div>
          </div>
        `;
      }).join("")}
      <p class="mayor-fuente">Tu mayor fuente es <strong>${nombreMayor}</strong></p>
    </section>

    <section class="challenge-card">
      <h3 class="challenge-title">🏆 Tu reto del mes</h3>
      <p class="challenge-text">${generarReto(mayorCatObj.key, localData?.state)}</p>
    </section>

    <section class="box-card">
      <h2 class="box-title">El detalle</h2>
      <table class="detail-table">
        <thead>
          <tr>
            <th>Qué</th>
            <th>kg CO₂e</th>
          </tr>
        </thead>
        <tbody>
          ${filasDetalle || `<tr><td colspan="2">Sin detalle desglosado disponible.</td></tr>`}
        </tbody>
      </table>
    </section>

    <details class="calc-details">
      <summary><span class="arrow-icon">▶</span> ¿Cómo lo calculamos?</summary>
      <div class="calc-content">
        <p>Multiplicamos tus consumos mensuales y trayectos al campus por los factores de emisión oficiales de la <strong>UPME (Colombia)</strong> para el Sistema Interconectado Nacional (0,220 kg CO₂e/kWh) y transporte terrestre, repartiendo el consumo del hogar entre las personas que viven en tu casa.</p>
        ${tablaOficialUpme}
      </div>
    </details>

    <a href="./encuesta.html" class="btn-outline-green">Cambiar mis respuestas</a>
  `;
}

cargarInforme();