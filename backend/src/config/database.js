require('dotenv').config();

const { Sequelize } = require('sequelize');

const sequelize = new Sequelize(
    process.env.DB_NAME,
    process.env.DB_USER,
    process.env.DB_PASS,
    {
        host: process.env.DB_HOST,
        port: process.env.DB_PORT,
        dialect: 'mysql',
        logging: false,
        timezone: '+07:00',
        define: {
            timestamps: false,
            freezeTableName: true
        },
        dialectOptions: {
            dateStrings: true,
            typeCast: true
        }
    }
);

module.exports = sequelize;