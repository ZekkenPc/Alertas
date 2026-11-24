'use strict';
const express = require('express');

module.exports = function servidoresRoutes({ store }) {
  const router = express.Router();

  router.get('/', (_req, res) => {
    res.json({ total: store.servers.length, servidores: store.servers });
  });

  return router;
};
