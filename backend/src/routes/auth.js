'use strict';
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// Hash ficticio para que el tiempo de respuesta sea parecido cuando el usuario no existe.
const DUMMY_HASH = '$2a$10$6rnrBd4GC4HAfsddtkwKn.cQ6/MfhWW3H.FLe6J4vrqvlipZqigiW';
const USUARIO_VALIDO = /^[A-Za-z0-9._-]+$/;

module.exports = function authRoutes({ store, jwtSecret }) {
  const router = express.Router();

  router.post('/login', async (req, res) => {
    const { usuario, clave } = req.body || {};

    const datosValidos =
      typeof usuario === 'string' && typeof clave === 'string' &&
      usuario.trim().length >= 1 && usuario.trim().length <= 30 &&
      USUARIO_VALIDO.test(usuario.trim()) &&
      clave.length >= 1 && clave.length <= 64;
    if (!datosValidos) return res.status(400).json({ error: 'Datos inválidos' });

    try {
      const user = store.users.find((u) => u.usuario === usuario.trim());
      const ok = await bcrypt.compare(clave, user ? user.claveHash : DUMMY_HASH);
      if (!user || !ok) {
        return res.status(401).json({ error: 'Credenciales inválidas' });
      }
      const token = jwt.sign({ id: user.id, rol: user.rol }, jwtSecret, {
        algorithm: 'HS256',
        expiresIn: '8h',
      });
      return res.json({
        token,
        usuario: { id: user.id, nombre: user.nombre, rol: user.rol },
      });
    } catch (err) {
      console.error('Error interno:', err && err.message);
      return res.status(500).json({ error: 'Error interno del servidor' });
    }
  });

  return router;
};
