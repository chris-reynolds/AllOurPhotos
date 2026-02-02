import express from 'express';
import User from '../models/User.js';
import { authenticateRequest, getUsernameAndId } from '../middleware/auth.js';
import sequelize from '../config/database.js';

const router = express.Router();

// Create user
router.post('/', authenticateRequest, async (req, res) => {
  try {
    const { username, userId } = await getUsernameAndId(req);
    const userData = {
      ...req.body,
      updated_user: username,
      created_on: new Date(),
      updated_on: new Date()
    };

    const user = await User.create(userData);
    const createdUser = await User.findByPk(user.id);
    console.log(`inserted User ${user.id}`);
    res.json(createdUser);
  } catch (error) {
    console.error('Error:', error);
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(409).json({ detail: error.message });
    } else {
      res.status(500).json({ detail: error.message });
    }
  }
});

// Get one user
router.get('/:id', authenticateRequest, async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) {
      return res.status(404).json({ detail: 'User not found' });
    }
    res.json(user);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

// Get many users
router.get('/', authenticateRequest, async (req, res) => {
  try {
    const { where = '1=0', orderby = 'id', limit = 1001, offset = 0 } = req.query;

    const users = await User.findAll({
      where: sequelize.literal(where),
      order: [[sequelize.literal(orderby)]],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    res.json(users);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

// Update user
router.put('/', authenticateRequest, async (req, res) => {
  try {
    const { id, ...updateData } = req.body;
    const { username, userId } = await getUsernameAndId(req);

    const oldUser = await User.findByPk(id);
    if (!oldUser) {
      return res.status(404).json({ detail: 'User not found' });
    }

    await User.update(
      {
        ...updateData,
        updated_user: username,
        updated_on: new Date()
      },
      {
        where: {
          id: id,
          updated_on: oldUser.updated_on
        }
      }
    );

    const updatedUser = await User.findByPk(id);
    res.json(updatedUser);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

// Delete user
router.delete('/:id', authenticateRequest, async (req, res) => {
  try {
    const { username, userId } = await getUsernameAndId(req);
    const oldUser = await User.findByPk(req.params.id);

    if (!oldUser) {
      return res.status(404).json({ detail: 'User not found' });
    }

    await User.destroy({ where: { id: req.params.id } });
    res.json(oldUser);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

export default router;
