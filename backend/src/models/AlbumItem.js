import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const AlbumItem = sequelize.define('AlbumItem', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true
  },
  created_on: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  updated_on: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW
  },
  updated_user: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  album_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'aopalbums',
      key: 'id'
    }
  },
  snap_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'aopsnaps',
      key: 'id'
    }
  }
}, {
  tableName: 'aopalbum_items',
  timestamps: false
});

export default AlbumItem;
