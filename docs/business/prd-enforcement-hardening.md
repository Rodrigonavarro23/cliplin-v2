# PRD: Enforcement Hardening — cycle-validate ejecuta, validators deterministas, contract tests

**Estado**: borrador para cycle-init (no gobierna nada todavía)
**Fecha**: 2026-07-19
**Origen**: evaluación independiente de Cliplin v2 contra el mercado SDD (Spec Kit, Kiro, BMAD, OpenSpec), basada en 2 días de desarrollo real en wedov2 (~8 ciclos, agente LLM conversacional multi-servicio). Informe completo entregado al humano 2026-07-19; evidencia local citada abajo.

## Problema

La evaluación confirmó que Cliplin v2 es el único framework del mercado con enforcement que bloquea, trazabilidad commit-level y memoria acumulativa — pero su falla más seria invalida parcialmente su promesa central:

1. **cycle-validate valida existencia de artefactos, no comportamiento.** En wedov2, la suite BDD (el gate de correctness que el propio proyecto declara en ADR-008) estuvo MESES rota por un error de sintaxis Gherkin (`@reason:` con espacios) y ningún ciclo `overall: pass` lo detectó. Un parse de 2 segundos lo habría atrapado. "Pass" hoy significa "los archivos existen y trazan", no "el sistema se comporta como el spec dice".
2. **AI-validando-AI es la pieza más frágil del sistema.** `acd-validate.sh` greppea el string `ACD-VALIDATION: PASS` sobre output libre de un `claude --print` anidado, con `|| true` tragándose errores. Documentado en vivo: 3 commits bloqueados por output basura del CLI anidado (respondía a notificaciones fantasma de background tasks en vez de correr el skill), resuelto con `SKIP=` manual. Además, la mayoría de sus checks (paths de `governed_by` existen, campos del commit message presentes) son deterministas — se paga fragilidad probabilística por trabajo greppeable.
3. **El framework no previno ninguna de las 5 fallas de integración real** del patrón "tests con fakes pasan / integración real falla" (contratos JSON entre servicios, límite de 64 bytes de Telegram callback_data, pairing de tool-responses de OpenAI). Las documentó bien a posteriori (context-summary), pero no existe regla de ciclo que exija contract tests.
4. **El cierre de ciclo depende de la disciplina del agente** (admitido en ADR-000 como "sequencing debt") y **el smoke live post-ciclo es recomendación informal** — en wedov2 detectó la 5ª falla en minutos, pero funcionó por disciplina, no por proceso.
5. **El context-summary no escala**: entradas narrativas de ~100 líneas (la del agente conversacional de wedov2) van a comerse ventanas de contexto.

## Objetivos (priorizados por retorno/costo)

### O1 — cycle-validate ejecuta, no solo lista (prioridad máxima, determinista, barato)
- Nuevos checks obligatorios de cierre:
  - **BV-1 (behavior gate)**: parseo Gherkin de TODO `docs/features/` (no solo el feature del ciclo) — un parse error en cualquier archivo es `overall: fail`.
  - **BV-2**: ejecución de la suite de tests de los paquetes tocados en la sesión (`go test ./paquetes...` o equivalente del stack), exit code literal como `evidence`.
  - **BV-3**: si el proyecto declara suite BDD y el ciclo tocó scenarios con step definitions, la suite BDD corre.
- Evidencia = salida real del comando, jamás narrada. Misma regla anti-fabricación que AC-1..4.

### O2 — Desacoplar checks deterministas del validator AI
- Script determinista (sin LLM) para: presencia de `@constraints`, existencia de paths `governed_by`, formato del commit message (líneas ACD-session/Artifacts/Scenarios — hoy además limitado por un `head -20` frágil), sintaxis Gherkin.
- El claude anidado queda SOLO para lo semántico (orphan code, consistencia spec/código, status tags vs staged diff), con: `--output-format json` o marcador estructurado, retry con backoff (≥2 intentos), y fallo explícito distinguible de "el CLI devolvió basura" (hoy indistinguibles).
- Presupuesto de latencia: el paso AI no debería superar ~2 min; el determinista, segundos.

### O3 — Regla de contract tests (TR-3)
- Nuevo check de trazabilidad: todo cliente inter-servicio o adapter de API externa NUEVO exige un test de contrato contra el response shape real (httptest/fixture con forma y longitud realistas — no `"cal-1"`).
- La lección ya existe como prosa en el context-summary de wedov2 (instancias 3-5); esto la eleva a regla de framework verificable.

### O4 — Smoke live formalizado
- Para ciclos que tocan wiring de runtime (composition root, router, config, main): el cierre incluye un ítem de smoke live (o su justificación explícita de por qué no aplica), registrado en el reporte.

### O5 — Higiene del context-summary
- Tope de tamaño por entrada de concepto (~25 líneas); lecciones-narrativa largas van a archivo propio (`docs/lessons/` o similar) referenciado por `find_via`.
- `context-summary-sync` valida el tope al escribir.

## No-objetivos

- No cambiar el modelo de specs (@constraints/Gherkin/TDR/ADR) — la evaluación lo validó como diferencial.
- No agregar RAG/vector DB — ADR-000 sigue vigente.
- No multi-host (otros CLIs) en este ciclo.
- No automatizar la decisión humana de cycle-init — el humano en el loop es feature, no bug.

## Métricas de éxito

- Un error de sintaxis Gherkin en cualquier feature file hace fallar el PRIMER cycle-validate posterior (hoy: nunca falla).
- Cero bypasses de validator por output basura en N ciclos (hoy: 3 en 2 días).
- Un cliente inter-servicio nuevo sin contract test no puede cerrar ciclo.
- Tiempo del paso determinista de validación: < 10 segundos.

## Evidencia citada

- wedov2: `.cliplin/cycles/*.json` (15 reportes), `.cliplin/context-summary.yaml` (instancias 1-5 del patrón fake-vs-real, R-009), commit `97237a1` (rescate de la BDD suite rota por meses), bypass documentado del validator en commit `2c3140c`.
- cliplin-v2: `docs/adrs/000-cliplin-v2-agent-native.md` (sequencing debt admitida), `plugins/cliplin-v2/skills/cycle-run/SKILL.md` (cycle-validate actual: AC-1..4 + TR-1..2, sin ejecución).
- Mercado: GitHub Spec Kit (checks advisory), AWS Kiro (gates solo en planning), OpenSpec (`verify` no bloquea) — ninguno ejecuta el gate que declara; Cliplin puede ser el primero.

## Siguiente paso

`cycle-init` sobre este PRD en el repo cliplin-v2 (es un proyecto Cliplin — dogfooding): detectará authorship/evolution de los features correspondientes (`cycle-run.feature` / `cycle-validate` / hooks) y producirá los `@constraints` con el humano decidiendo prioridades y cortes de fase. Sugerencia de fases: O1+O2 primero (deterministas, retorno máximo), O3 segundo, O4+O5 después.
