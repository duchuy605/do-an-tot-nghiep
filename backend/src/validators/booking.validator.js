const Joi = require('joi');

const createBookingSchema = Joi.object({
  MaNhanVien: Joi.number().integer().allow(null),
  MaLoaiGoi: Joi.number().integer().allow(null),
  NgayBatDau: Joi.string().isoDate().required(),
  NgayKetThuc: Joi.string().isoDate().required(),
  ThuTrongTuan: Joi.string().max(20).allow(null, ''),
  LoaiDatLich: Joi.number().valid(1, 2).default(1),
  DiaChiLamViec: Joi.string().max(255).required(),
  GioBatDau: Joi.string().regex(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$/).required().messages({
    'string.pattern.base': 'Giờ bắt đầu không đúng định dạng HH:mm'
  }),
  GioKetThuc: Joi.string().regex(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$/).required().messages({
    'string.pattern.base': 'Giờ kết thúc không đúng định dạng HH:mm'
  }),
  MoTaCongViec: Joi.string().max(255).allow(null, ''),
  DichVus: Joi.array().items(
    Joi.object({
      MaDichVu: Joi.number().integer().required(),
      SoLuong: Joi.number().integer().min(1).default(1),
      LaDichVuChinh: Joi.boolean().default(true)
    })
  ).min(1).required()
});

module.exports = {
  createBookingSchema
};
