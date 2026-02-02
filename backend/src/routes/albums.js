import express from 'express';
import Album from '../models/Album.js';
import { authenticateRequest, getUsernameAndId } from '../middleware/auth.js';
import sequelize from '../config/database.js';

const router = express.Router();

// Create album
router.post('/', authenticateRequest, async (req, res) => {
  try {
    const { username, userId } = await getUsernameAndId(req);
    const albumData = {
      ...req.body,
      updated_user: username,
      user_id: userId,
      created_on: new Date(),
      updated_on: new Date()
    };

    const album = await Album.create(albumData);
    const createdAlbum = await Album.findByPk(album.id);
    res.json(createdAlbum);
  } catch (error) {
    console.error('Error:', error);
    if (error.name === 'SequelizeUniqueConstraintError') {
      res.status(409).json({ detail: error.message });
    } else {
      res.status(500).json({ detail: error.message });
    }
  }
});

// Get one album
router.get('/:id', authenticateRequest, async (req, res) => {
  try {
    const album = await Album.findByPk(req.params.id);
    if (!album) {
      return res.status(404).json({ detail: 'Album not found' });
    }
    res.json(album);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

// Get many albums
router.get('/', authenticateRequest, async (req, res) => {
  try {
    const { where = '1=0', orderby = 'id', limit = 1001, offset = 0 } = req.query;

    const albums = await Album.findAll({
      where: sequelize.literal(where),
      order: [[sequelize.literal(orderby)]],
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    res.json(albums);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

// Update album
router.put('/', authenticateRequest, async (req, res) => {
  try {
    const { id, ...updateData } = req.body;
    const { username, userId } = await getUsernameAndId(req);

    const oldAlbum = await Album.findByPk(id);
    if (!oldAlbum) {
      return res.status(404).json({ detail: 'Album not found' });
    }

    await Album.update(
      {
        ...updateData,
        updated_user: username,
        updated_on: new Date()
      },
      {
        where: {
          id: id,
          updated_on: oldAlbum.updated_on
        }
      }
    );

    const updatedAlbum = await Album.findByPk(id);
    res.json(updatedAlbum);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

// Delete album
router.delete('/:id', authenticateRequest, async (req, res) => {
  try {
    const { username, userId } = await getUsernameAndId(req);
    const oldAlbum = await Album.findByPk(req.params.id);

    if (!oldAlbum) {
      return res.status(404).json({ detail: 'Album not found' });
    }

    await Album.destroy({ where: { id: req.params.id } });
    res.json(oldAlbum);
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ detail: error.message });
  }
});

export default router;
