const { Sequelize, DataTypes } = require('sequelize');

const sequelize = new Sequelize('booking_giup_viec', 'root', '', {
  host: 'localhost',
  dialect: 'mysql', // Assuming mysql
  logging: false
});

const LichSuViTien = sequelize.define('LichSuViTien', {
  MaGiaoDich: { type: DataTypes.INTEGER, primaryKey: true },
  MaViNguon: DataTypes.INTEGER,
  MaViDich: DataTypes.INTEGER,
  LoaiGiaoDich: DataTypes.INTEGER,
  SoTien: DataTypes.DECIMAL(18, 0),
  SoDuSau: DataTypes.DECIMAL(18, 0),
  NgayTao: DataTypes.DATE
}, {
  tableName: 'LichSuViTien',
  timestamps: false
});

async function run() {
  try {
    const history = await LichSuViTien.findAll({
      order: [['NgayTao', 'DESC']],
      limit: 10
    });
    console.log(JSON.stringify(history, null, 2));
  } catch (err) {
    console.error(err);
  } finally {
    await sequelize.close();
  }
}

run();
