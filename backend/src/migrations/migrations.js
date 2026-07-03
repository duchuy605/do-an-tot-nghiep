const { sequelize } = require('../models');

async function up() {
  console.log('--- BAT DAU CHAY MIGRATIONS (TAO CACP BANG) ---');
  try {
    // Sync all models in order. force: true will drop tables if they exist and recreate them
    await sequelize.sync({ force: true });
    console.log('-> Migrations da hoan thanh thanh cong! Tat ca cac bang da duoc tao.');
  } catch (error) {
    console.error('Xay ra loi khi chay migrations:', error);
    throw error;
  }
}

async function down() {
  console.log('--- BAT DAU ROLLBACK MIGRATIONS (XOA CAC BANG) ---');
  try {
    // Drop all tables
    await sequelize.drop();
    console.log('-> Rollback hoan thanh! Tat ca cac bang da bi xoa.');
  } catch (error) {
    console.error('Xay ra loi khi rollback migrations:', error);
    throw error;
  }
}

module.exports = {
  up,
  down
};

// Chay truc tiep neu duoc goi tu dong lenh
if (require.main === module) {
  up().then(() => process.exit(0)).catch(() => process.exit(1));
}
