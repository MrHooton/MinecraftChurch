/**
 * Known Players Routes
 * Handles registration and lookup of known players.
 *
 * Identity rule: UUID is authoritative when present. Player names are mutable labels.
 * A same-name/different-UUID collision is rejected rather than silently rebinding identity.
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
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({
          error: 'Validation failed',
          details: errors.array()
        });
      }

      const { player_name, uuid, platform = 'unknown' } = req.body;

      // Look up both axes independently. UUID is authoritative whenever supplied.
      const existingByName = await db.query(
        'SELECT * FROM known_players WHERE player_name = ?',
        [player_name]
      );

      let existingByUuid = [];
      if (uuid) {
        existingByUuid = await db.query(
          'SELECT * FROM known_players WHERE uuid = ?',
          [uuid]
        );
      }

      // Protect against the dangerous case: a familiar name arrives with a different UUID.
      // Never silently overwrite the UUID attached to an existing identity.
      if (uuid && existingByName.length > 0) {
        const namedRecord = existingByName[0];
        if (namedRecord.uuid && String(namedRecord.uuid).toLowerCase() !== String(uuid).toLowerCase()) {
          console.warn(
            `[IDENTITY] Name collision refused: ${player_name} requested ${uuid}, stored UUID is ${namedRecord.uuid}`
          );
          return res.status(409).json({
            error: 'Identity collision',
            message: 'Player name is already associated with a different UUID',
            player_name,
            stored_uuid: namedRecord.uuid,
            supplied_uuid: uuid
          });
        }
      }

      // UUID already exists: update the current label/platform by UUID.
      if (uuid && existingByUuid.length > 0) {
        await db.query(
          `UPDATE known_players
           SET player_name = ?, platform = ?, last_seen_at = NOW()
           WHERE uuid = ?`,
          [player_name, platform, uuid]
        );

        return res.json({
          success: true,
          message: 'Player updated by UUID',
          player_name,
          uuid,
          action: 'updated_by_uuid'
        });
      }

      // Existing name with no UUID is a legacy record. It is safe to backfill once.
      if (existingByName.length > 0) {
        const namedRecord = existingByName[0];

        if (uuid && !namedRecord.uuid) {
          await db.query(
            `UPDATE known_players
             SET uuid = ?, platform = ?, last_seen_at = NOW()
             WHERE player_name = ?`,
            [uuid, platform, player_name]
          );

          return res.json({
            success: true,
            message: 'Legacy player UUID backfilled',
            player_name,
            uuid,
            action: 'uuid_backfilled'
          });
        }

        // Compatibility path for callers that do not provide a UUID.
        // This updates activity/platform only and never changes identity.
        await db.query(
          `UPDATE known_players
           SET platform = ?, last_seen_at = NOW()
           WHERE player_name = ?`,
          [platform, player_name]
        );

        return res.json({
          success: true,
          message: 'Player refreshed by name without UUID rebinding',
          player_name,
          uuid: namedRecord.uuid || null,
          action: 'updated_name_only'
        });
      }

      // Brand-new identity.
      await db.query(
        `INSERT INTO known_players (player_name, uuid, platform)
         VALUES (?, ?, ?)`,
        [player_name, uuid || null, platform]
      );

      return res.status(201).json({
        success: true,
        message: 'Player registered',
        player_name,
        uuid: uuid || null,
        action: 'created'
      });

    } catch (error) {
      console.error('Error registering player:', error);
      return res.status(500).json({
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
      // Optional authentication - skip if secret not configured
      if (config.api.secret && config.api.secret !== '') {
        const apiSecret = req.headers['x-api-secret'];
        if (!apiSecret || apiSecret !== config.api.secret) {
          return res.status(401).json({
            error: 'Unauthorized',
            message: 'Invalid or missing API secret'
          });
        }
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

      return res.json({
        success: true,
        player: players[0]
      });

    } catch (error) {
      console.error('Error fetching player:', error);
      return res.status(500).json({
        error: 'Internal server error',
        message: 'Failed to fetch player information'
      });
    }
  }
);

/**
 * Compatibility endpoint: POST /api/player-seen
 * Denizen calls on join; uses the same UUID-first registration logic.
 * Body: { player_name, uuid (optional), platform }
 */
router.post('/player-seen',
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
    req.url = '/register';
    return router.handle(req, res);
  }
);

module.exports = router;
