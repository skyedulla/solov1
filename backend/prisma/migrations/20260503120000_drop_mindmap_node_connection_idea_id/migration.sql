-- Drop denormalized idea_id; scope is implied by mindmap_id → mindmaps.idea_id.
ALTER TABLE "mindmap_nodes" DROP COLUMN "idea_id";
ALTER TABLE "mindmap_connections" DROP COLUMN "idea_id";
