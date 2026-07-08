const Joi = require('joi');

const createReviewSchema = Joi.object({
  MaCaLam: Joi.number().integer().required(),
  SoSao: Joi.number().integer().min(1).max(5).required(),
  NoiDungDanhGia: Joi.string().max(255).allow(null, '')
});

const createComplaintSchema = Joi.object({
  MaCaLam: Joi.number().integer().required(),
  TieuDe: Joi.string().max(255).required(),
  NoiDung: Joi.string().max(255).required()
});

const rescheduleShiftSchema = Joi.object({
  NgayLamViec: Joi.string().pattern(/^\d{4}-\d{2}-\d{2}$/).required(),
  GioBatDau: Joi.string().pattern(/^\d{2}:\d{2}(:\d{2})?$/).required(),
  GioKetThuc: Joi.string().pattern(/^\d{2}:\d{2}(:\d{2})?$/).optional().allow(null, ''),
  LyDo: Joi.string().max(255).allow(null, '')
});

module.exports = {
  createReviewSchema,
  createComplaintSchema,
  rescheduleShiftSchema
};
