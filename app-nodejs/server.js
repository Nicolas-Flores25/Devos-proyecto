const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('Hola Mundo desde Node.js en el pipeline DevOps!');
});

app.listen(port, () => {
  console.log(`Aplicación Node.js corriendo en el puerto ${port}`);
});
