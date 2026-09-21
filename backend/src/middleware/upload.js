import multer from 'multer';
import path from 'node:path';
import { AppError, ErrorCodes } from '../utils/response.js';

const IMAGE_EXTENSIONS = new Set([
  '.png', '.jpg', '.jpeg', '.webp', '.gif', '.tiff', '.tif', '.bmp', '.avif',
]);
const VIDEO_EXTENSIONS = new Set(['.mp4', '.mov', '.avi', '.mkv', '.webm']);
export const IMAGE_MIME = new Set([
  'image/png', 'image/jpeg', 'image/webp', 'image/gif', 'image/tiff', 'image/bmp', 'image/avif',
]);
export const VIDEO_MIME = new Set([
  'video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/x-matroska', 'video/webm',
]);

function toMimeType(filename, mimetype) {
  const ext = path.extname(filename || '').toLowerCase();
  if (mimetype && mimetype.startsWith('image/')) return 'image';
  if (mimetype && mimetype.startsWith('video/')) return 'video';
  if (IMAGE_EXTENSIONS.has(ext)) return 'image';
  if (VIDEO_EXTENSIONS.has(ext)) return 'video';
  return null;
}

export function isSupportedFile(filename, mimetype) {
  return toMimeType(filename, mimetype) !== null;
}

const storage = multer.memoryStorage();

export const uploadImage = multer({
  storage,
  limits: { fileSize: Number(process.env.MAX_IMAGE_SIZE_MB || 10) * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (toMimeType(file.originalname, file.mimetype) !== 'image') {
      return cb(new AppError(400, ErrorCodes.INVALID_FILE_TYPE, 'Only image files are supported.'));
    }
    cb(null, true);
  },
});

export const uploadVideo = multer({
  storage,
  limits: { fileSize: Number(process.env.MAX_VIDEO_SIZE_MB || 50) * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (toMimeType(file.originalname, file.mimetype) !== 'video') {
      return cb(new AppError(400, ErrorCodes.INVALID_FILE_TYPE, 'Only video files are supported.'));
    }
    cb(null, true);
  },
});

// Accepts either an image or a video for the same endpoint.
export const uploadMedia = multer({
  storage,
  limits: { fileSize: Number(process.env.MAX_VIDEO_SIZE_MB || 50) * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    if (toMimeType(file.originalname, file.mimetype) === null) {
      return cb(new AppError(400, ErrorCodes.INVALID_FILE_TYPE, 'Unsupported file type.'));
    }
    cb(null, true);
  },
});