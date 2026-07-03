const jwt = require('jsonwebtoken');
require('dotenv').config();

const secret = process.env.JWT_SECRET || 'super_secret_jwt_key_helpservice_2026';
const expires = process.env.JWT_EXPIRES_IN || '7d';

function generateToken(payload) {
  return jwt.sign(payload, secret, { expiresIn: expires });
}

function verifyToken(token) {
  try {
    return jwt.verify(token, secret);
  } catch (error) {
    return null;
  }
}

module.exports = {
  generateToken,
  verifyToken
};
