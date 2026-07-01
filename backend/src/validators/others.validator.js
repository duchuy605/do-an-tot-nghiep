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

module.exports = {
  createReviewSchema,
  createComplaintSchema
};
