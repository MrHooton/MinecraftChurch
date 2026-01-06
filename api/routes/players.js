/**
 * Known Players Routes
 * Handles registration and lookup of known players
 */

const express = require('express');
const router = express.Router();
const db = require('../db');
const config = require('../config');
const { body, validationResult } = require('express-validator');

/**
 * Register or update a known player
 * POST /api/players/register
 * Body: { player_name, uuid (optional), platform }
 * Headers: X-API-Secret (for authentication from Denizen)
 */
router.post('/register',
  [
    body('player_name')
      .trim()
      .isLength({ min: 1, max: 16 })
      .matches(/^[a-zA-Z0-9_]+$/)
      .withMessage('Player name must be 1-16 characters, alphanumeric and underscores only'),
    body('uuid')
      .optional()
      .isUUID()
      .withMessage('UUID must be a valid UUID format'),
    body('platform')
      .optional()
      .isIn(['java', 'bedrock', 'unknown'])
      .withMessage('Platform must be one of: java, bedrock, unknown')
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

      const { player_name, uuid, platform = 'unknown' } = req.body;

      // Check if player already exists
      const existing = await db.query(
        'SELECT * FROM known_players WHERE player_name = ?',
        [player_name]
      );

      if (existing.length > 0) {
        // Update existing player
        await db.query(
          `UPDATE known_players 
           SET uuid = COALESCE(?, uuid), 
               platform = ?,
               last_seen_at = NOW()
           WHERE player_name = ?`,
          [uuid || null, platform, player_name]
        );

        res.json({
          success: true,
          message: 'Player updated',
          player_name: player_name,
          action: 'updated'
        });
      } else {
        // Insert new player
        await db.query(
          `INSERT INTO known_players (player_name, uuid, platform)
           VALUES (?, ?, ?)`,
          [player_name, uuid || null, platform]
        );

        res.status(201).json({
          success: true,
          message: 'Player registered',
          player_name: player_name,
          action: 'created'
        });
      }

    } catch (error) {
      console.error('Error registering player:', error);
      res.status(500).json({ 
        error: 'Internal server error',
        message: 'Failed to register player' 
      });
    }
  }
);

/**
 * Get player information
 * GET /api/players/:player_name
 * Headers: X-API-Secret (optional, for Denizen)
 */
router.get('/:player_name',
  async (req, res) => {
    try {
      // Optional authentication - allow unauthenticated for basic lookups
      const apiSecret = req.headers['x-api-secret'];
      const requiresAuth = false; // Set to true if you want to require auth

      if (requiresAuth && (!apiSecret || apiSecret !== config.api.secret)) {
        return res.status(401).json({ 
          error: 'Unauthorized',
          message: 'Invalid or missing API secret' 
        });
      }

      const { player_name } = req.params;

      const players = await db.query(
        'SELECT * FROM known_players WHERE player_name = ?',
        [player_name]
      );

      if (players.length === 0) {
        return res.status(404).json({ 
          error: 'Not found',
          message: 'Player not found' 
        });
      }

      res.json({
        success: true,
        player: players[0]
      });

    } catch (error) {
      console.error('Error fetching player:', error);
      res.status(500).json({ 
        error: 'Internal server error',
        message: 'Failed to fetch player information' 
      });
    }
  }
);

module.exports = router;
