/**
 * Access Grants Routes
 * Handles polling and status updates for access grants
 */

const express = require('express');
const router = express.Router();
const db = require('../db');
const config = require('../config');
const { body, validationResult, param } = require('express-validator');

/**
 * Get pending access grants (for Denizen polling)
 * GET /api/grants/pending
 * Headers: X-API-Secret (for authentication from Denizen)
 */
router.get('/pending',
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

      const grants = await db.query(
        `SELECT ag.*, vr.child_name, vr.adult_name
         FROM access_grants ag
         INNER JOIN verification_requests vr ON ag.request_id = vr.id
         WHERE ag.status = 'approved'
         ORDER BY ag.created_at ASC
         LIMIT 100`
      );

      res.json({
        success: true,
        count: grants.length,
        grants: grants
      });

    } catch (error) {
      console.error('Error fetching pending grants:', error);
      res.status(500).json({ 
        error: 'Internal server error',
        message: 'Failed to fetch pending grants' 
      });
    }
  }
);

/**
 * Mark a grant as applied (after Denizen applies it via LuckPerms)
 * POST /api/grants/:id/applied
 * Body: { applied_by (optional) }
 * Headers: X-API-Secret
 */
router.post('/:id/applied',
  [
    param('id').isInt().withMessage('Grant ID must be an integer'),
    body('applied_by')
      .optional()
      .trim()
      .isLength({ max: 255 })
      .withMessage('Applied by must be 255 characters or less')
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

      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ 
          error: 'Validation failed',
          details: errors.array() 
        });
      }

      const { id } = req.params;
      const { applied_by } = req.body;

      // Get the grant
      const grants = await db.query(
        'SELECT * FROM access_grants WHERE id = ?',
        [id]
      );

      if (grants.length === 0) {
        return res.status(404).json({ 
          error: 'Not found',
          message: 'Access grant not found' 
        });
      }

      const grant = grants[0];

      if (grant.status !== 'approved') {
        return res.status(400).json({ 
          error: 'Invalid status',
          message: `Grant is already ${grant.status}` 
        });
      }

      // Update grant status
      await db.query(
        `UPDATE access_grants 
         SET status = 'applied', applied_at = NOW()
         WHERE id = ?`,
        [id]
      );

      // Log to audit log
      await db.query(
        `INSERT INTO audit_log (action_type, admin_user, target_player, grant_id, details)
         VALUES (?, ?, ?, ?, ?)`,
        [
          'grant_applied',
          applied_by || 'denizen_script',
          grant.player_name,
          id,
          JSON.stringify({ grant_type: grant.grant_type, grant_value: grant.grant_value })
        ]
      );

      res.json({
        success: true,
        message: 'Grant marked as applied',
        grant_id: id
      });

    } catch (error) {
      console.error('Error marking grant as applied:', error);
      res.status(500).json({ 
        error: 'Internal server error',
        message: 'Failed to update grant status' 
      });
    }
  }
);

/**
 * Mark a grant as failed (if Denizen fails to apply it)
 * POST /api/grants/:id/failed
 * Body: { error: "error message" }
 * Headers: X-API-Secret
 */
router.post('/:id/failed',
  [
    param('id').isInt().withMessage('Grant ID must be an integer'),
    body('error')
      .trim()
      .isLength({ min: 1, max: 65535 })
      .withMessage('Error message is required')
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

      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ 
          error: 'Validation failed',
          details: errors.array() 
        });
      }

      const { id } = req.params;
      const { error } = req.body;

      // Get the grant
      const grants = await db.query(
        'SELECT * FROM access_grants WHERE id = ?',
        [id]
      );

      if (grants.length === 0) {
        return res.status(404).json({ 
          error: 'Not found',
          message: 'Access grant not found' 
        });
      }

      const grant = grants[0];

      // Update grant status
      await db.query(
        `UPDATE access_grants 
         SET status = 'failed', error = ?
         WHERE id = ?`,
        [error, id]
      );

      // Log to audit log
      await db.query(
        `INSERT INTO audit_log (action_type, target_player, grant_id, details)
         VALUES (?, ?, ?, ?)`,
        [
          'grant_failed',
          grant.player_name,
          id,
          JSON.stringify({ error: error })
        ]
      );

      res.json({
        success: true,
        message: 'Grant marked as failed',
        grant_id: id
      });

    } catch (error) {
      console.error('Error marking grant as failed:', error);
      res.status(500).json({ 
        error: 'Internal server error',
        message: 'Failed to update grant status' 
      });
    }
  }
);

module.exports = router;
