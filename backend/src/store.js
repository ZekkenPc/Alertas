'use strict';
// Almacén en memoria inicializado con datos de ejemplo.
// En una versión posterior puede sustituirse por una base de datos real
// sin cambiar las rutas (solo este archivo).
const seed = require('../data/seed.json');
const users = require('../data/users.json');

const MAX_INCIDENTS = 50;

function createStore() {
  const now = Date.now();

  const incidents = seed.incidentes.map((i) => ({
    id: i.id,
    titulo: i.titulo,
    servidor: i.servidor,
    servicio: i.servicio,
    severidad: i.severidad,
    estado: 'activo',
    detectado: new Date(now - i.hace_min * 60000).toISOString(),
    descripcion: i.descripcion,
    logs: [...i.logs],
  }));

  const servers = seed.servidores.map((s) => ({ ...s }));

  let counter =
    Math.max(...incidents.map((i) => Number(i.id.split('-')[1]))) + 1;

  function addIncident({ titulo, servidor, servicio, severidad, descripcion, logs }) {
    const incident = {
      id: `INC-${counter++}`,
      titulo,
      servidor,
      servicio: servicio || '',
      severidad,
      estado: 'activo',
      detectado: new Date().toISOString(),
      descripcion: descripcion || '',
      logs: logs || [],
    };
    incidents.unshift(incident);
    if (incidents.length > MAX_INCIDENTS) incidents.length = MAX_INCIDENTS;
    return incident;
  }

  return {
    users,
    incidents,
    servers,
    addIncident,
    findServer: (nombre) => servers.find((s) => s.nombre === nombre),
    findIncident: (id) => incidents.find((i) => i.id === id),
  };
}

module.exports = { createStore };
