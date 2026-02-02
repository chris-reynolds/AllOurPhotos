import express from 'express';
import Snap from '../models/Snap.js';
import { authenticateRequest, getUsernameAndId } from '../middleware/auth.js';
import sequelize from '../config/database.js';

const router = express.Router();

// Create snap
router.post('/', authenticateRequest, async (req, res) => {
  try {
    const { username, userId } = await getUsernameAndId(req);
    const snapData = {
      ...req.body,
      updated_user: username,
      user_id: userId,
      session_id: req.session.id,
      created_on: new Date(),
      updated_on: new Date()
    };

    const snap = await Snap.create(snapData);
    const createdSnap = await Snap.findByPk(snap.id);
    console.log(`inserted Snap ${snap.id}`);
    res.json(createdSnap);
  } catch (error) {
    console.error('Error:', error);
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(409).json({ detail: error.message });
    } else {
      res.status(500).json({ detail: error.message });
    }
  }
});

// Get one snap
router.get('/:id', authenticateRequest, async (req, res) => {
  try {
    const snap = await Snap.findByPk(req.params.id);
    if (!snap) {
      return res.status(404).json({ detail: 'Snap not found' });
    }
    res.json(snap);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

// Get many snaps
router.get('/', async (req, res) => {
  try {
    const { where = '1=0', orderby = 'id', limit = 1001, offset = 0 } = req.query;

    const snaps = await Snap.findAll({
      where: sequelize.literal(where),
      order: [[sequelize.literal(orderby)]],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    res.json(snaps);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: `aaa ${error.message}` });
  }
});

// Update snap
router.put('/', authenticateRequest, async (req, res) => {
  try {
    const { id, ...updateData } = req.body;
    const { username, userId } = await getUsernameAndId(req);

    const oldSnap = await Snap.findByPk(id);
    if (!oldSnap) {
      return res.status(404).json({ detail: 'Snap not found' });
    }

    await Snap.update(
      {
        ...updateData,
        updated_user: username,
        updated_on: new Date()
      },
      {
        where: {
          id: id,
          updated_on: oldSnap.updated_on
        }
      }
    );

    const updatedSnap = await Snap.findByPk(id);
    res.json(updatedSnap);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

// Delete snap
router.delete('/:id', authenticateRequest, async (req, res) => {
  try {
    const { username, userId } = await getUsernameAndId(req);
    const oldSnap = await Snap.findByPk(req.params.id);

    if (!oldSnap) {
      return res.status(404).json({ detail: 'Snap not found' });
    }

    await Snap.destroy({ where: { id: req.params.id } });
    res.json(oldSnap);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

export default router;
