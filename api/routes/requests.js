/**
 * Verification Requests Routes
 * Handles submission and management of verification requests
 */

const express = require('express');
const router = express.Router();
const db = require('../db');
const config = require('../config');
const { body, validationResult, param } = require('express-validator');

/**
 * Submit a verification request from Wix form
 * POST /api/requests/submit
 * Body: { child_name, adult_name (optional), code, parent_name, parent_email, consent, church (optional), adult_join }
 */
router.post('/submit',
  [
    body('child_name')
      .trim()
      .isLength({ min: 1, max: 16 })
      .matches(/^[a-zA-Z0-9_]+$/)
      .withMessage('Child name must be 1-16 characters, alphanumeric and underscores only'),
    body('adult_name')
      .optional()
      .trim()
      .isLength({ min: 1, max: 16 })
      .matches(/^[a-zA-Z0-9_]+$/)
      .withMessage('Adult name must be 1-16 characters, alphanumeric and underscores only'),
    body('code')
      .trim()
      .isLength({ min: 6, max: 6 })
      .matches(/^[A-Z0-9]+$/)
      .withMessage('Code must be exactly 6 alphanumeric characters'),
    body('parent_name')
      .trim()
      .isLength({ min: 1, max: 255 })
      .withMessage('Parent name is required and must be 1-255 characters'),
    body('parent_email')
      .trim()
      .isEmail()
      .normalizeEmail()
      .withMessage('Valid parent email is required'),
    body('consent')
      .isBoolean()
      .withMessage('Consent must be a boolean value'),
    body('church')
      .optional()
      .trim()
      .isLength({ max: 255 })
      .withMessage('Church name must be 255 characters or less'),
    body('adult_join')
      .optional()
      .isBoolean()
      .withMessage('adult_join must be a boolean value')
  ],
  async (req, res) => {
    try {
      // Validate input
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ 
          error: 'Validation failed',
          details: errors.array() 
        });
      }

      const {
        child_name,
        adult_name,
        code,
        parent_name,
        parent_email,
        consent,
        church,
        adult_join
      } = req.body;

      // Verify code exists and is valid
      const codeRecords = await db.query(
        `SELECT code, child_name, expires_at, used_at 
         FROM verification_codes 
         WHERE code = ?`,
        [code]
      );

      if (codeRecords.length === 0) {
        return res.status(400).json({ 
          error: 'Invalid code',
          message: 'Verification code not found' 
        });
      }

      const codeRecord = codeRecords[0];

      // Check if code is expired
      if (new Date(codeRecord.expires_at) < new Date()) {
        return res.status(400).json({ 
          error: 'Code expired',
          message: 'This verification code has expired' 
        });
      }

      // Check if code is already used
      if (codeRecord.used_at !== null) {
        return res.status(400).json({ 
          error: 'Code already used',
          message: 'This verification code has already been used' 
        });
      }

      // Verify child name matches
      if (codeRecord.child_name.toLowerCase() !== child_name.toLowerCase()) {
        return res.status(400).json({ 
          error: 'Code mismatch',
          message: 'Verification code does not match the child name' 
        });
      }

      // Check if consent is given
      if (!consent) {
        return res.status(400).json({ 
          error: 'Consent required',
          message: 'Parental consent is required to proceed' 
        });
      }

      // Get client IP address
      const clientIp = req.ip || req.connection.remoteAddress || 
                      req.headers['x-forwarded-for']?.split(',')[0] || 'unknown';

      // Start transaction
      const connection = await db.getConnection();
      await connection.beginTransaction();

      try {
        // Mark code as used
        await connection.execute(
          `UPDATE verification_codes 
           SET used_at = NOW(), used_by_email = ?, used_ip = ?
           WHERE code = ?`,
          [parent_email, clientIp, code]
        );

        // Create verification request
        const [result] = await connection.execute(
          `INSERT INTO verification_requests 
           (child_name, adult_name, code, parent_name, parent_email, consent, church, adult_join, status)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending')`,
          [
            child_name,
            adult_name || null,
            code,
            parent_name,
            parent_email,
            consent ? 1 : 0,
            church || null,
            adult_join ? 1 : 0
          ]
        );

        await connection.commit();
        connection.release();

        res.status(201).json({
          success: true,
          request_id: result.insertId,
          message: 'Verification request submitted successfully. Awaiting admin approval.',
          status: 'pending'
        });

      } catch (error) {
        await connection.rollback();
        connection.release();
        throw error;
      }

    } catch (error) {
      console.error('Error submitting verification request:', error);
      res.status(500).json({ 
        error: 'Internal server error',
        message: 'Failed to submit verification request' 
      });
    }
  }
);

/**
 * Get all verification requests (with optional filtering)
 * GET /api/requests?status=pending&limit=50
 * Headers: X-Admin-Token (for authentication)
 */
router.get('/',
  async (req, res) => {
    try {
      // Validate authentication
      const adminToken = req.headers['x-admin-token'];
      if (!adminToken || adminToken !== config.api.adminToken) {
        return res.status(401).json({ 
          error: 'Unauthorized',
          message: 'Invalid or missing admin token' 
        });
      }

      const { status, limit = 50, offset = 0 } = req.query;

      let sql = 'SELECT * FROM verification_requests';
      const params = [];

      if (status) {
        sql += ' WHERE status = ?';
        params.push(status);
      }

      sql += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
      params.push(parseInt(limit), parseInt(offset));

      const requests = await db.query(sql, params);

      res.json({
        success: true,
        count: requests.length,
        requests: requests
      });

    } catch (error) {
      console.error('Error fetching verification requests:', error);
      res.status(500).json({ 
        error: 'Internal server error',
        message: 'Failed to fetch verification requests' 
      });
    }
  }
);

/**
 * Get a specific verification request by ID
 * GET /api/requests/:id
 * Headers: X-Admin-Token
 */
router.get('/:id',
  [
    param('id').isInt().withMessage('Request ID must be an integer')
  ],
  async (req, res) => {
    try {
      // Validate authentication
      const adminToken = req.headers['x-admin-token'];
      if (!adminToken || adminToken !== config.api.adminToken) {
        return res.status(401).json({ 
          error: 'Unauthorized',
          message: 'Invalid or missing admin token' 
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

      const requests = await db.query(
        'SELECT * FROM verification_requests WHERE id = ?',
        [id]
      );

      if (requests.length === 0) {
        return res.status(404).json({ 
          error: 'Not found',
          message: 'Verification request not found' 
        });
      }

      res.json({
        success: true,
        request: requests[0]
      });

    } catch (error) {
      console.error('Error fetching verification request:', error);
      res.status(500).json({ 
        error: 'Internal server error',
        message: 'Failed to fetch verification request' 
      });
    }
  }
);

/**
 * Approve a verification request
 * POST /api/requests/:id/approve
 * Body: { approved_by, notes (optional) }
 * Headers: X-Admin-Token
 */
router.post('/:id/approve',
  [
    param('id').isInt().withMessage('Request ID must be an integer'),
    body('approved_by')
      .trim()
      .isLength({ min: 1, max: 255 })
      .withMessage('Approved by field is required'),
    body('notes')
      .optional()
      .trim()
      .isLength({ max: 65535 })
      .withMessage('Notes must be less than 65535 characters')
  ],
  async (req, res) => {
    try {
      // Validate authentication
      const adminToken = req.headers['x-admin-token'];
      if (!adminToken || adminToken !== config.api.adminToken) {
        return res.status(401).json({ 
          error: 'Unauthorized',
          message: 'Invalid or missing admin token' 
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
      const { approved_by, notes } = req.body;

      // Get the request
      const requests = await db.query(
        'SELECT * FROM verification_requests WHERE id = ?',
        [id]
      );

      if (requests.length === 0) {
        return res.status(404).json({ 
          error: 'Not found',
          message: 'Verification request not found' 
        });
      }

      const request = requests[0];

      if (request.status !== 'pending') {
        return res.status(400).json({ 
          error: 'Invalid status',
          message: `Request is already ${request.status}` 
        });
      }

      // Start transaction
      const connection = await db.getConnection();
      await connection.beginTransaction();

      try {
        // Update request status
        await connection.execute(
          `UPDATE verification_requests 
           SET status = 'approved', approved_by = ?, approved_at = NOW(), notes = ?
           WHERE id = ?`,
          [approved_by, notes || null, id]
        );

        // Create access grants
        const grants = [];

        // Grant for child
        grants.push({
          request_id: id,
          player_name: request.child_name,
          grant_type: 'group',
          grant_value: 'child',
          status: 'approved'
        });

        // Grant for adult if applicable
        if (request.adult_join && request.adult_name) {
          grants.push({
            request_id: id,
            player_name: request.adult_name,
            grant_type: 'group',
            grant_value: 'adult',
            status: 'approved'
          });
        }

        // Insert grants
        for (const grant of grants) {
          await connection.execute(
            `INSERT INTO access_grants (request_id, player_name, grant_type, grant_value, status)
             VALUES (?, ?, ?, ?, ?)`,
            [grant.request_id, grant.player_name, grant.grant_type, grant.grant_value, grant.status]
          );
        }

        // Log to audit log
        await connection.execute(
          `INSERT INTO audit_log (action_type, admin_user, target_player, request_id, details)
           VALUES (?, ?, ?, ?, ?)`,
          [
            'approve',
            approved_by,
            request.child_name,
            id,
            JSON.stringify({ notes: notes || null, grants_created: grants.length })
          ]
        );

        await connection.commit();
        connection.release();

        res.json({
          success: true,
          message: 'Verification request approved',
          request_id: id,
          grants_created: grants.length
        });

      } catch (error) {
        await connection.rollback();
        connection.release();
        throw error;
      }

    } catch (error) {
      console.error('Error approving verification request:', error);
      res.status(500).json({ 
        error: 'Internal server error',
        message: 'Failed to approve verification request' 
      });
    }
  }
);

/**
 * Reject a verification request
 * POST /api/requests/:id/reject
 * Body: { approved_by, notes (required - rejection reason) }
 * Headers: X-Admin-Token
 */
router.post('/:id/reject',
  [
    param('id').isInt().withMessage('Request ID must be an integer'),
    body('approved_by')
      .trim()
      .isLength({ min: 1, max: 255 })
      .withMessage('Approved by field is required'),
    body('notes')
      .trim()
      .isLength({ min: 1, max: 65535 })
      .withMessage('Rejection reason (notes) is required')
  ],
  async (req, res) => {
    try {
      // Validate authentication
      const adminToken = req.headers['x-admin-token'];
      if (!adminToken || adminToken !== config.api.adminToken) {
        return res.status(401).json({ 
          error: 'Unauthorized',
          message: 'Invalid or missing admin token' 
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
      const { approved_by, notes } = req.body;

      // Get the request
      const requests = await db.query(
        'SELECT * FROM verification_requests WHERE id = ?',
        [id]
      );

      if (requests.length === 0) {
        return res.status(404).json({ 
          error: 'Not found',
          message: 'Verification request not found' 
        });
      }

      const request = requests[0];

      if (request.status !== 'pending') {
        return res.status(400).json({ 
          error: 'Invalid status',
          message: `Request is already ${request.status}` 
        });
      }

      // Start transaction
      const connection = await db.getConnection();
      await connection.beginTransaction();

      try {
        // Update request status
        await connection.execute(
          `UPDATE verification_requests 
           SET status = 'rejected', approved_by = ?, approved_at = NOW(), notes = ?
           WHERE id = ?`,
          [approved_by, notes, id]
        );

        // Log to audit log
        await connection.execute(
          `INSERT INTO audit_log (action_type, admin_user, target_player, request_id, details)
           VALUES (?, ?, ?, ?, ?)`,
          [
            'reject',
            approved_by,
            request.child_name,
            id,
            JSON.stringify({ reason: notes })
          ]
        );

        await connection.commit();
        connection.release();

        res.json({
          success: true,
          message: 'Verification request rejected',
          request_id: id
        });

      } catch (error) {
        await connection.rollback();
        connection.release();
        throw error;
      }

    } catch (error) {
      console.error('Error rejecting verification request:', error);
      res.status(500).json({ 
        error: 'Internal server error',
        message: 'Failed to reject verification request' 
      });
    }
  }
);

module.exports = router;
