const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
const port = 3000;

app.use(cors());
app.use(bodyParser.json());

const db = mysql.createConnection({
  host: '127.0.0.1',
  user: 'root',
  password: '',
  database: 'kenea_masterdata',
});

db.connect((err) => {
  if (err) {
    console.error('Error connecting to MySQL:', err);
    return;
  }
  console.log('Connected to MySQL');
});

app.get('/dsps', (req, res) => {
  const query = 'SELECT sales_rep_id, sales_rep_name, ' +
                'SUM(CASE WHEN status = \'Active/Approved\' THEN 1 ELSE 0 END) as active_count, ' +
                'SUM(CASE WHEN status = \'Blocked/On hold\' THEN 1 ELSE 0 END) as blocked_count ' +
                'FROM KENEA_CML ' +
                'GROUP BY sales_rep_id, sales_rep_name';
  db.query(query, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

app.get('/customers/:dspId', (req, res) => {
  const { dspId } = req.params;
  const { status, coverageDay, wklyCoverage } = req.query;
  let query = 'SELECT * FROM KENEA_CML WHERE sales_rep_id = ?';
  const params = [dspId];

  if (status) {
    query += ' AND status = ?';
    params.push(status);
  }
  if (coverageDay) {
    query += ' AND coverage_day = ?';
    params.push(coverageDay);
  }
  if (wklyCoverage) {
    query += ' AND wkly_coverage = ?';
    params.push(wklyCoverage);
  }

  db.query(query, params, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

app.get('/customers', (req, res) => {
  const { province, city, barangay } = req.query;
  let query = 'SELECT customer_code, customer_name, address FROM KENEA_CML WHERE 1=1';
  const params = [];

  if (province) {
    query += ' AND province = ?';
    params.push(province);
  }
  if (city) {
    query += ' AND city = ?';
    params.push(city);
  }
  if (barangay) {
    query += ' AND barangay = ?';
    params.push(barangay);
  }

  db.query(query, params, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

app.get('/counts', (req, res) => {
  const query = 'SELECT COUNT(*) as overall, ' +
                'SUM(CASE WHEN status = \'Active/Approved\' THEN 1 ELSE 0 END) as active, ' +
                'SUM(CASE WHEN status = \'Blocked/On hold\' THEN 1 ELSE 0 END) as inactive ' +
                'FROM KENEA_CML';
  db.query(query, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results[0]);
  });
});

app.put('/customers/:customerCode/status', (req, res) => {
  const { customerCode } = req.params;
  const { status } = req.body;
  const query = 'UPDATE KENEA_CML SET status = ? WHERE customer_code = ?';
  db.query(query, [status, customerCode], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: 'Status updated' });
  });
});

app.put('/customers/:customerCode', (req, res) => {
  const { customerCode } = req.params;
  const { customerName, coverageDay, wklyCoverage, phone, owner, barangay, city, province, address } = req.body;
  const query = 'UPDATE KENEA_CML SET customer_name = ?, coverage_day = ?, wkly_coverage = ?, phone = ?, owner = ?, barangay = ?, city = ?, province = ?, address = ? WHERE customer_code = ?';
  db.query(query, [customerName, coverageDay, wklyCoverage, phone, owner, barangay, city, province, address, customerCode], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: 'Customer updated' });
  });
});

app.put('/customers/:customerCode/location', (req, res) => {
  const { customerCode } = req.params;
  const { latitude, longitude } = req.body;
  const query = 'UPDATE KENEA_CML SET latitude = ?, longitude = ? WHERE customer_code = ?';
  db.query(query, [latitude, longitude, customerCode], (err, result) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: 'Location updated' });
  });
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
