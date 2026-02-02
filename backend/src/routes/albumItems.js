import express from 'express';
import AlbumItem from '../models/AlbumItem.js';
import { authenticateRequest, getUsernameAndId } from '../middleware/auth.js';
import sequelize from '../config/database.js';

const router = express.Router();

// Create album item
router.post('/', authenticateRequest, async (req, res) => {
  try {
    const { username, userId } = await getUsernameAndId(req);
    const albumItemData = {
      ...req.body,
      updated_user: username,
      created_on: new Date(),
      updated_on: new Date()
    };

    const albumItem = await AlbumItem.create(albumItemData);
    const createdAlbumItem = await AlbumItem.findByPk(albumItem.id);
    console.log(`inserted AlbumItem ${albumItem.id}`);
    res.json(createdAlbumItem);
  } catch (error) {
    console.error('Error:', error);
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(409).json({ detail: error.message });
    } else {
      res.status(500).json({ detail: error.message });
    }
  }
});

// Get one album item
router.get('/:id', authenticateRequest, async (req, res) => {
  try {
    const albumItem = await AlbumItem.findByPk(req.params.id);
    if (!albumItem) {
      return res.status(404).json({ detail: 'AlbumItem not found' });
    }
    res.json(albumItem);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

// Get many album items
router.get('/', authenticateRequest, async (req, res) => {
  try {
    const { where = '1=0', orderby = 'id', limit = 1001, offset = 0 } = req.query;

    const albumItems = await AlbumItem.findAll({
      where: sequelize.literal(where),
      order: [[sequelize.literal(orderby)]],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    res.json(albumItems);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

// Update album item
router.put('/', authenticateRequest, async (req, res) => {
  try {
    const { id, ...updateData } = req.body;
    const { username, userId } = await getUsernameAndId(req);

    const oldAlbumItem = await AlbumItem.findByPk(id);
    if (!oldAlbumItem) {
      return res.status(404).json({ detail: 'AlbumItem not found' });
    }

    await AlbumItem.update(
      {
        ...updateData,
        updated_user: username,
        updated_on: new Date()
      },
      {
        where: {
          id: id,
          updated_on: oldAlbumItem.updated_on
        }
      }
    );

    const updatedAlbumItem = await AlbumItem.findByPk(id);
    res.json(updatedAlbumItem);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

// Delete album item
router.delete('/:id', authenticateRequest, async (req, res) => {
  try {
    const { username, userId } = await getUsernameAndId(req);
    const oldAlbumItem = await AlbumItem.findByPk(req.params.id);

    if (!oldAlbumItem) {
      return res.status(404).json({ detail: 'AlbumItem not found' });
    }

    await AlbumItem.destroy({ where: { id: req.params.id } });
    res.json(oldAlbumItem);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

export default router;
