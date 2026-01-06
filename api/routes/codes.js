/**
 * Verification Codes Routes
 * Handles generation and validation of verification codes
 */

const express = require('express');
const router = express.Router();
const db = require('../db');
const config = require('../config');
const { body, validationResult } = require('express-validator');

/**
 * Generate a new verification code for a child
 * POST /api/codes/generate
 * Body: { child_name, child_uuid (optional) }
 * Headers: X-API-Secret (for authentication from Denizen)
 */
router.post('/generate', 
  [
    body('child_name')
      .trim()
      .isLength({ min: 1, max: 16 })
      .matches(/^[a-zA-Z0-9_]+$/)
      .withMessage('Child name must be 1-16 characters, alphanumeric and underscores only'),
    body('child_uuid')
      .optional()
      .isUUID()
      .withMessage('Child UUID must be a valid UUID format')
  ],
  async (req, res) => {
    try {
      // Validate authentication
      const apiSecret = req.headers['x-api-secret'];
      if (!apiSecret || apiSecret !== config.api.secret) {
        return res.status(401).json({ 
          error: 'Unauthorized',
          message: 'Invalid or missing API secret' 
        });
      }

      // Validate input
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ 
          error: 'Validation failed',
          details: errors.array() 
        });
      }

      const { child_name, child_uuid } = req.body;

      // Generate a random 6-character code
      let code = generateCode(config.security.codeLength);

      // Check if code already exists (unlikely but possible)
      let existingCode = await db.query(
        'SELECT code FROM verification_codes WHERE code = ?',
        [code]
      );

      // Regenerate if collision (very rare)
      let attempts = 0;
      while (existingCode.length > 0 && attempts < 10) {
        code = generateCode(config.security.codeLength);
        existingCode = await db.query(
          'SELECT code FROM verification_codes WHERE code = ?',
          [code]
        );
        attempts++;
      }

      if (attempts >= 10) {
        return res.status(500).json({ 
          error: 'Code generation failed',
          message: 'Unable to generate unique code after multiple attempts' 
        });
      }

      // Calculate expiration time
      const expiresAt = new Date();
      expiresAt.setMinutes(expiresAt.getMinutes() + config.security.codeExpirationMinutes);

      // Insert code into database
      await db.query(
        `INSERT INTO verification_codes (code, child_name, child_uuid, expires_at)
         VALUES (?, ?, ?, ?)`,
        [code, child_name, child_uuid || null, expiresAt]
      );

      res.status(201).json({
        success: true,
        code: code,
        child_name: child_name,
        expires_at: expiresAt.toISOString(),
        expires_in_minutes: config.security.codeExpirationMinutes
      });

    } catch (error) {
      console.error('Error generating verification code:', error);
      res.status(500).json({ 
        error: 'Internal server error',
        message: 'Failed to generate verification code' 
      });
    }
  }
);

/**
 * Generate a random alphanumeric code
 */
function generateCode(length) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excludes confusing chars (0, O, I, 1)
  let code = '';
  for (let i = 0; i < length; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

module.exports = router;
