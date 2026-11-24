'use strict';
// Pruebas adicionales de integración del backend (Práctica 13-14).
// Complementan api.test.js: seguridad del token, recursos inexistentes,
// consistencia del resumen, validación de límites y límite de intentos.
const test = require('node:test');
const assert = require('node:assert');
const jwt = require('jsonwebtoken');
const { createApp } = require('../src/app');

async function start(opts = {}) {
  const { app, store } = createApp({ jwtSecret: 'test-secret', loginLimit: 1000, ...opts });
  const server = await new Promise((resolve) => {
    const s = app.listen(0, () => resolve(s));
  });
  const base = `http://127.0.0.1:${server.address().port}`;
  const call = async (path, { method = 'GET', token, body } = {}) => {
    const headers = {};
    if (token) headers.Authorization = `Bearer ${token}`;
    if (body !== undefined) headers['Content-Type'] = 'application/json';
    const res = await fetch(base + path, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
    return { status: res.status, json: await res.json() };
  };
  const login = (usuario, clave) =>
    call('/api/auth/login', { method: 'POST', body: { usuario, clave } });
  return { server, store, call, login };
}

test('AUT-05 token manipulado o firmado con otra clave responde 401', async () => {
  const { server, call } = await start();
  const ajeno = jwt.sign({ id: 1, rol: 'coordinador' }, 'otra-clave', { algorithm: 'HS256' });
  assert.equal((await call('/api/incidentes', { token: ajeno })).status, 401);
  assert.equal((await call('/api/incidentes', { token: 'abc.def.ghi' })).status, 401);
  server.close();
});

test('AUT-05 token expirado responde 401', async () => {
  const { server, call } = await start();
  const vencido = jwt.sign({ id: 1, rol: 'tecnico' }, 'test-secret', {
    algorithm: 'HS256',
    expiresIn: -10,
  });
  assert.equal((await call('/api/servidores', { token: vencido })).status, 401);
  server.close();
});

test('AUT-05 GET /api/incidentes/:id devuelve 200 si existe y 404 si no', async () => {
  const { server, call, login } = await start();
  const { json } = await login('tecnico1', 'Tecnico#2026');
  const lista = await call('/api/incidentes', { token: json.token });
  const id = lista.json.incidentes[0].id;
  const ok = await call(`/api/incidentes/${id}`, { token: json.token });
  assert.equal(ok.status, 200);
  assert.equal(ok.json.id, id);
  const no = await call('/api/incidentes/INC-999999', { token: json.token });
  assert.equal(no.status, 404);
  server.close();
});

test('AUT-05 /api/resumen es consistente con la lista de incidentes', async () => {
  const { server, call, login } = await start();
  const { json } = await login('coordinador', 'Coord#2026');
  const r = await call('/api/resumen', { token: json.token });
  assert.equal(r.status, 200);
  const { P1, P2, P3 } = r.json.por_severidad;
  assert.equal(P1 + P2 + P3, r.json.incidentes_activos);
  const srv = r.json.servidores;
  const s = await call('/api/servidores', { token: json.token });
  assert.equal(srv.en_linea + srv.degradado + srv.caido, s.json.total);
  server.close();
});

test('AUT-04 POST /api/incidentes rechaza valores fuera de rango', async () => {
  const { server, call, login } = await start();
  const token = (await login('coordinador', 'Coord#2026')).json.token;
  const base = { titulo: 'Prueba de alerta', servidor: 'APP-WEB-01', severidad: 'P2' };
  const intentos = [
    { ...base, titulo: 'ab' },
    { ...base, titulo: 'x'.repeat(121) },
    { ...base, severidad: 'P9' },
    { ...base, logs: new Array(21).fill('linea') },
    { ...base, logs: ['x'.repeat(201)] },
    { ...base, descripcion: 'd'.repeat(501) },
  ];
  for (const body of intentos) {
    const r = await call('/api/incidentes', { method: 'POST', token, body });
    assert.equal(r.status, 400, JSON.stringify(body).slice(0, 60));
  }
  server.close();
});

test('AUT-04 el incidente creado queda disponible por id', async () => {
  const { server, call, login } = await start();
  const token = (await login('coordinador', 'Coord#2026')).json.token;
  const creado = await call('/api/incidentes', {
    method: 'POST',
    token,
    body: { titulo: 'Alerta de prueba', servidor: 'APP-WEB-01', severidad: 'P1', logs: ['ERROR x'] },
  });
  assert.equal(creado.status, 201);
  const leido = await call(`/api/incidentes/${creado.json.id}`, { token });
  assert.equal(leido.status, 200);
  assert.equal(leido.json.titulo, 'Alerta de prueba');
  assert.deepEqual(leido.json.logs, ['ERROR x']);
  server.close();
});

test('AUT-04 el login se bloquea con 429 al superar el límite de intentos', async () => {
  const { server, login } = await start({ loginLimit: 2 });
  assert.equal((await login('coordinador', 'Mala#12345')).status, 401);
  assert.equal((await login('coordinador', 'Mala#12345')).status, 401);
  assert.equal((await login('coordinador', 'Coord#2026')).status, 429);
  server.close();
});

test('ruta inexistente responde 404 con JSON genérico', async () => {
  const { server, call } = await start();
  const r = await call('/api/no-existe');
  assert.equal(r.status, 404);
  assert.deepEqual(r.json, { error: 'No encontrado' });
  server.close();
});
