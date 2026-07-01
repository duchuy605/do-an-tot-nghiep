const { HinhThucXuLy, sequelize } = require('./src/models');

async function seedHinhThucXuLy() {
  try {
    await sequelize.authenticate();
    console.log('Connected to database.');

    const existing = await HinhThucXuLy.count();
    if (existing > 0) {
      console.log(`Already has ${existing} resolution types. Skipping seed.`);
      const all = await HinhThucXuLy.findAll();
      all.forEach(t => console.log(`  ${t.MaHinhThucXuLy}: ${t.TenHinhThuc}`));
      process.exit(0);
      return;
    }

    await HinhThucXuLy.bulkCreate([
      { TenHinhThuc: 'Hoàn tiền khách hàng' },
      { TenHinhThuc: 'Cảnh cáo nhân viên' },
      { TenHinhThuc: 'Trừ lương nhân viên' },
      { TenHinhThuc: 'Đình chỉ nhân viên tạm thời' },
      { TenHinhThuc: 'Khóa tài khoản nhân viên' },
    ]);

    console.log('Seeded 5 resolution types successfully!');
    const all = await HinhThucXuLy.findAll();
    all.forEach(t => console.log(`  ${t.MaHinhThucXuLy}: ${t.TenHinhThuc}`));
    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

seedHinhThucXuLy();
