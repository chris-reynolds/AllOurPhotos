import Session from '../models/Session.js';
import User from '../models/User.js';

export const authenticateRequest = async (req, res, next) => {
  try {
    let preserve = req.cookies.Preserve || req.headers.preserve;

    if (!preserve) {
      return res.status(401).json({ detail: 'Unauthorized: No Preserve cookie or header found' });
    }

    let jam;
    try {
      const preserveData = JSON.parse(preserve);
      jam = preserveData.jam;
    } catch (error) {
      return res.status(401).json({ detail: 'Unauthorized: Invalid Preserve format' });
    }

    if (!jam) {
      return res.status(403).json({ detail: 'No musicians' });
    }

    const session = await Session.findByPk(parseInt(jam));
    if (!session) {
      return res.status(404).json({ detail: 'Session not found' });
    }

    req.session = session;
    next();
  } catch (error) {
    console.error('Authentication error:', error);
    res.status(500).json({ detail: error.message });
  }
};

export const getUserFromSession = async (session) => {
  const user = await User.findByPk(session.user_id);
  if (!user) {
    throw new Error('User not found');
  }
  return user;
};

export const getUsernameAndId = async (req) => {
  const user = await getUserFromSession(req.session);
  return { username: user.name, userId: user.id };
};
