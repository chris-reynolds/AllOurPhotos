import express from 'express';
import Session from '../models/Session.js';
import { authenticateRequest, getUsernameAndId } from '../middleware/auth.js';
import sequelize from '../config/database.js';

const router = express.Router();

// Create session
router.post('/', authenticateRequest, async (req, res) => {
  try {
    const { username, userId } = await getUsernameAndId(req);
    const sessionData = {
      ...req.body,
      updated_user: username,
      user_id: userId,
      created_on: new Date(),
      updated_on: new Date()
    };

    const session = await Session.create(sessionData);
    const createdSession = await Session.findByPk(session.id);
    console.log(`inserted Session ${session.id}`);
    res.json(createdSession);
  } catch (error) {
    console.error('Error:', error);
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(409).json({ detail: error.message });
    } else {
      res.status(500).json({ detail: error.message });
    }
  }
});

// Get one session
router.get('/:id', authenticateRequest, async (req, res) => {
  try {
    const session = await Session.findByPk(req.params.id);
    if (!session) {
      return res.status(404).json({ detail: 'Session not found' });
    }
    res.json(session);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

// Get many sessions
router.get('/', async (req, res) => {
  try {
    const { where = '1=0', orderby = 'id', limit = 1001, offset = 0 } = req.query;

    const sessions = await Session.findAll({
      where: sequelize.literal(where),
      order: [[sequelize.literal(orderby)]],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    res.json(sessions);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

// Update session
router.put('/', authenticateRequest, async (req, res) => {
  try {
    const { id, ...updateData } = req.body;
    const { username, userId } = await getUsernameAndId(req);

    const oldSession = await Session.findByPk(id);
    if (!oldSession) {
      return res.status(404).json({ detail: 'Session not found' });
    }

    await Session.update(
      {
        ...updateData,
        updated_user: username,
        updated_on: new Date()
      },
      {
        where: {
          id: id,
          updated_on: oldSession.updated_on
        }
      }
    );

    const updatedSession = await Session.findByPk(id);
    res.json(updatedSession);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

// Delete session
router.delete('/:id', authenticateRequest, async (req, res) => {
  try {
    const { username, userId } = await getUsernameAndId(req);
    const oldSession = await Session.findByPk(req.params.id);

    if (!oldSession) {
      return res.status(404).json({ detail: 'Session not found' });
    }

    await Session.destroy({ where: { id: req.params.id } });
    res.json(oldSession);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

export default router;
