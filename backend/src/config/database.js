require('dotenv').config();
const { Sequelize } = require('sequelize');

const dialect = process.env.DB_DIALECT || 'mysql';
let sequelize;

if (dialect === 'MySQL') {
  const path = require('path');
  const storagePath = process.env.DB_STORAGE || path.join(__dirname, '../../database.MySQL');
  sequelize = new Sequelize({
    dialect: 'MySQL',
    storage: storagePath,
    logging: false,
    define: {
      timestamps: false,
      freezeTableName: true
    }
  });
} else {
  const database = process.env.DB_NAME || 'booking_giup_viec';
  const username = process.env.DB_USER || 'root';
  const password = process.env.DB_PASS || '';
  const host = process.env.DB_HOST || '127.0.0.1';
  const port = process.env.DB_PORT || 3306;

  sequelize = new Sequelize(database, username, password, {
    host: host,
    port: port,
    dialect: 'mysql',
    logging: false, // Đặt console.log to see SQL queries
    timezone: '+07:00', // Vietnam timezone
    define: {
      timestamps: false, // Set false because the schema diagrams handles timestamps explicitly
      freezeTableName: true
    },
    dialectOptions: {
      dateStrings: true,
      typeCast: true
    }
  });
}

module.exports = sequelize;
