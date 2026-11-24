# HuellaViva UAN

Prototipo academico de la Universidad Antonio NariÃ±o (UAN) para estimar la huella de carbono de la comunidad universitaria (estudiantes, profesores y administrativos).

> **Advertencia institucional:** HuellaViva UAN es un estimador educativo y de diagnostico institucional. NO es un inventario institucional verificado, ni una certificacion ambiental, ni una compensacion de emisiones, ni un resultado oficial de RENARE, ni un inventario de ciclo de vida completo.

## Ejecucion local
1. Ejecutar en Supabase SQL Editor: `001_esquema_base.sql`, `002_rls_triggers_y_agregados.sql` y `seed.sql`.
2. Configurar `PUBLIC_SUPABASE_URL` y `PUBLIC_SUPABASE_ANON_KEY` en `src/js/config.js`.
3. Servir la carpeta raiz con `npx serve .` y abrir `http://localhost:3000/src/index.html`.
4. Ejecutar pruebas unitarias: `node --test tests/calculo.test.mjs`.