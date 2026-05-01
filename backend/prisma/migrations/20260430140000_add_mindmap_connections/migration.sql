-- CreateEnum
CREATE TYPE "MindmapConnectionAnchor" AS ENUM ('top', 'right', 'left', 'bottom');

-- CreateTable
CREATE TABLE "mindmap_connections" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "idea_id" TEXT NOT NULL,
    "mindmap_id" TEXT NOT NULL,
    "source_node_id" TEXT NOT NULL,
    "target_node_id" TEXT,
    "source_anchor" "MindmapConnectionAnchor" NOT NULL,
    "target_anchor" "MindmapConnectionAnchor",
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "mindmap_connections_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "mindmap_connections_user_id_idx" ON "mindmap_connections"("user_id");

-- CreateIndex
CREATE INDEX "mindmap_connections_user_id_mindmap_id_idx" ON "mindmap_connections"("user_id", "mindmap_id");
