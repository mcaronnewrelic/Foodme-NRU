/**
 * URL utilities for consistent slug generation
 */

/**
 * Convert restaurant name to URL-safe slug
 * Example: "BBQ Tofu Paradise" -> "bbq_tofu_paradise"
 */
function nameToSlug(name) {
  return name
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s]/g, '') // Remove special characters except spaces
    .replace(/\s+/g, '_') // Replace spaces with underscores
    .replace(/_+/g, '_') // Replace multiple underscores with single
    .replace(/^_|_$/g, ''); // Remove leading/trailing underscores
}

/**
 * Convert URL slug back to search pattern for database lookup
 * Example: "bbq_tofu_paradise" -> "BBQ Tofu Paradise" (approximately)
 */
function slugToSearchPattern(slug) {
  return slug
    .replace(/_/g, ' ') // Replace underscores with spaces
    .toLowerCase()
    .trim();
}

module.exports = {
  nameToSlug,
  slugToSearchPattern
};