-- CreateTable
CREATE TABLE "mindmap_nodes" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "idea_id" TEXT NOT NULL,
    "mindmap_id" TEXT NOT NULL,
    "parent_node_id" TEXT,
    "position_x" INTEGER NOT NULL,
    "position_y" INTEGER NOT NULL,
    "text" TEXT NOT NULL DEFAULT '',
    "width" INTEGER NOT NULL,
    "height" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "mindmap_nodes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "mindmap_nodes_user_id_idx" ON "mindmap_nodes"("user_id");

-- CreateIndex
CREATE INDEX "mindmap_nodes_user_id_mindmap_id_idx" ON "mindmap_nodes"("user_id", "mindmap_id");
