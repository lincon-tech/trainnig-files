const express = require('express');
const sql = require('mssql');
require('dotenv').config();

const app = express();
const port = 3000;

const config = {
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    server: process.env.DB_SERVER,
    database: process.env.DB_NAME,
    options: {
        encrypt: true, // for Azure
        trustServerCertificate: false
    }
};

app.get('/', async (req, res) => {
    try {
        await sql.connect(config);
        const result = await sql.query('SELECT * FROM Inventory');
        res.send(result.recordset);
    } catch (err) {
        res.status(500).send(err.message);
    }
});

app.listen(port, () => console.log(`App running on http://localhost:${port}`));