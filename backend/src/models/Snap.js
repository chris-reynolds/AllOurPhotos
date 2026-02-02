import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const Snap = sequelize.define('Snap', {
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
  file_name: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  directory: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  taken_date: {
    type: DataTypes.DATE,
    allowNull: true
  },
  original_taken_date: {
    type: DataTypes.DATE,
    allowNull: true
  },
  modified_date: {
    type: DataTypes.DATE,
    allowNull: true
  },
  device_name: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  caption: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  ranking: {
    type: DataTypes.INTEGER,
    defaultValue: 2
  },
  longitude: {
    type: DataTypes.FLOAT,
    allowNull: true
  },
  latitude: {
    type: DataTypes.FLOAT,
    allowNull: true
  },
  width: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  height: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  location: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  rotation: {
    type: DataTypes.STRING(10),
    allowNull: true
  },
  degrees: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  },
  import_source: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  media_type: {
    type: DataTypes.STRING(50),
    allowNull: true
  },
  imported_date: {
    type: DataTypes.DATE,
    allowNull: true
  },
  media_length: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  tag_list: {
    type: DataTypes.STRING(255),
    allowNull: true
  },
  metadata: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  session_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'aopsessions',
      key: 'id'
    }
  },
  user_id: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'aopusers',
      key: 'id'
    }
  }
}, {
  tableName: 'aopsnaps',
  timestamps: false
});

export default Snap;
